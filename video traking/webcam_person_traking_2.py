import os
from pickle import TRUE
from turtle import width
# this line suppresses errors multiple OpenMP, but does not work
os.environ['KMP_DUPLICATE_LIB_OK'] = 'TRUE'
import time
from typing import Sequence

import pafy
import cv2
import fire
import numpy as np
import torch
import torchvision
import torchvision.transforms as transforms
from motpy import Detection, ModelPreset, MultiObjectTracker, NpImage
from motpy.core import setup_logger
from motpy.detector import BaseObjectDetector
from motpy.testing_viz import draw_detection, draw_track
from motpy.utils import ensure_packages_installed

from pythonosc import udp_client
from numpy import mean

from coco_labels import get_class_ids

ensure_packages_installed(['torch', 'torchvision', 'cv2'])


"""

    Usage:

        python examples/webcam_person_traking_2.py \
            --video_path=./assets/video.mp4 \
            --detect_labels=["person"] \
            --tracker_min_iou=0.2 \
            --architecture=fasterrcnn \
            --device=cuda

python ./webcam_person_traking_2.py    --video_path='../CPAC-2022-Project/video traking/video examples/PETS09-S2L1-raw.webm'  --detect_labels=["person"]  --tracker_min_iou=0.2  --architecture=fasterrcnn  --device=cpu
"""

video_downscale = 1 # default does not resize image

video_path = './video examples/PETS09-S2L1-raw.webm'
# video_path = './video examples/PETS09-S2L2-raw.webm'
# video_path = './video examples/AVG-TownCentre-raw.webm'
# video_path = './video examples/MOT20-06-raw.webm'
# video_path = '' # uncomment to activate webcam input
# video_path = "https://www.youtube.com/watch?v=1-iS7LArMPA" # NY
# video_path = "https://www.youtube.com/watch?v=z4WeAR7tctA" # NY live walking
# video_path = "https://www.youtube.com/watch?v=h1wly909BYw"; video_downscale = 0.5 # Petersburg - ok
# video_path = "https://www.youtube.com/watch?v=PGrq-2mju2s" # time square


IP = '127.0.0.1'
# PORT = 57120 # supercollider
PORT = 3000  # processing


logger = setup_logger(__name__, 'DEBUG', is_main=True)


class CocoObjectDetector(BaseObjectDetector):
    """ A wrapper of torchvision example object detector trained on COCO dataset """

    def __init__(self,
                 class_ids: Sequence[int],
                 confidence_threshold: float = 0.5,
                 architecture: str = 'fcos',
                 device: str = 'cpu'):

        self.confidence_threshold = confidence_threshold
        self.device = device
        self.class_ids = class_ids
        assert len(self.class_ids) > 0, f'select more than one class_ids'

        if architecture == 'ssdlite320':
            self.model = torchvision.models.detection.ssdlite320_mobilenet_v3_large(pretrained=True)
            # self.model = torchvision.models.detection.ssdlite320_mobilenet_v3_large(weights=SSDLite320_MobileNet_V3_Large_Weights.DEFAULT)
            # fast but unaccurate, have also to lower the confidence_threshold
        elif architecture == 'fasterrcnn':
            self.model = torchvision.models.detection.fasterrcnn_resnet50_fpn(pretrained=True)
            # accurate but slow
        elif architecture == 'fasterrcnn2':
            self.model = torchvision.models.detection.fasterrcnn_resnet50_fpn_v2(pretrained=True)
            # super slow
        elif architecture == 'fasterrcnnMob':
            self.model = torchvision.models.detection.fasterrcnn_mobilenet_v3_large_fpn(pretrained=True)
            # quite good, but quite slow, cof thr=0.7
        elif architecture == 'fasterrcnnMob320':
            self.model = torchvision.models.detection.fasterrcnn_mobilenet_v3_large_320_fpn(pretrained=True)
            # fast but not good
        elif architecture == 'fcos':
            self.model = torchvision.models.detection.fcos_resnet50_fpn(pretrained=True)
            # super slow
        elif architecture == 'ssd300':
            self.model = torchvision.models.detection.ssd300_vgg16(pretrained=True)
        elif architecture == 'retina':
            self.model = torchvision.models.detection.retinanet_resnet50_fpn(pretrained=True)
        elif architecture == 'retina2':
            self.model = torchvision.models.detection.retinanet_resnet50_fpn_v2(pretrained=True)
        else:
            raise NotImplementedError(f'unknown architecture: {architecture}')

        self.model = self.model.eval().to(device)

        self.input_transform = transforms.Compose([
            transforms.ToTensor(),
        ])

    def _predict(self, image):
        image = self.input_transform(image).to(self.device).unsqueeze(0)
        with torch.no_grad():
            pred = self.model(image)

        outs = [pred[0][attr].detach().cpu().numpy() for attr in ['boxes', 'scores', 'labels']]

        sel = np.logical_and(
            np.isin(outs[2], self.class_ids),  # only selected class_ids
            outs[1] >= self.confidence_threshold)  # above confidence threshold

        return [outs[idx][sel].astype(to_type) for idx, to_type in enumerate([float, int, float])]

    def process_image(self, image: NpImage) -> Sequence[Detection]:
        t0 = time.time()
        boxes, scores, class_ids = self._predict(image)
        elapsed = (time.time() - t0) * 1000.
        logger.debug(f'inference time: {elapsed:.3f} ms')
        return [Detection(box=b, score=s, class_id=l) for b, s, l in zip(boxes, scores, class_ids)]


def read_video_file(video_path: str):
    if "youtube" in video_path:
        video = pafy.new(video_path)
        best = video.getbest(preftype="mp4")
        cap = cv2.VideoCapture(best.url)
        video_fps = 10
    else:
        video_path = os.path.expanduser(video_path)
        cap = cv2.VideoCapture(video_path)
        video_fps = float(cap.get(cv2.CAP_PROP_FPS))
    return cap, video_fps

# def center(boxArray, imgHeight, imgWidth):
def center(boxArray):
    # [xmin, ymin, xmax, ymax]
    # print(boxArray.shape, boxArray[1:2])
    # print(boxArray,boxArray[0])
    # return [mean(boxArray[0:2:3])/imgWidth, mean(boxArray[1:2:3])/imgHeight]
    return [ ((boxArray[0]+boxArray[2])/2)/imgWidth, ((boxArray[1]+boxArray[3])/2)/imgHeight]

def osc_message_boid(track):
    # prepare the osc message for a single track
    return [ordered_ids.index(track.id), is_new_id[ordered_ids.index(track.id)]] + center(track.box)


def run(video_path: str = video_path, detect_labels = ["person"],
        video_downscale: float = video_downscale,
        architecture: str = 'fasterrcnnMob',
        confidence_threshold: float = 0.7,
        tracker_min_iou: float = 0.35,
        show_detections: bool = True,
        track_text_verbose: int = 0,
        device: str = 'cuda',
        viz_wait_ms: int = 1):
    # setup detector, video reader and object tracker
    print(detect_labels)
    print(get_class_ids(detect_labels))
    print()
    detector = CocoObjectDetector(class_ids=get_class_ids(detect_labels), confidence_threshold=confidence_threshold, architecture=architecture, device=device)
    # for person should be: class_ids=1
    detector = CocoObjectDetector(class_ids=[1], confidence_threshold=confidence_threshold, architecture=architecture, device=device)
    # car and trucks are 3,8
    # detector = CocoObjectDetector(class_ids=[3, 8], confidence_threshold=confidence_threshold, architecture=architecture, device=device)
    if video_path:
        cap, cap_fps = read_video_file(video_path)
    else:
        cap = cv2.VideoCapture(0)
        cap_fps = 15 # 15 fps


    tracker = MultiObjectTracker(
        dt=1 / cap_fps,
        tracker_kwargs={'max_staleness': 5},
        model_spec={'order_pos': 1, 'dim_pos': 2,
                    'order_size': 0, 'dim_size': 2,
                    'q_var_pos': 5000., 'r_var_pos': 0.1},
        matching_fn_kwargs={'min_iou': tracker_min_iou,
                            # 'multi_match_min_iou': 0.93})
                            'multi_match_min_iou': 1. + 1e-7})

    # udp client for sending OSC messages
    client = udp_client.SimpleUDPClient(IP, PORT)

    global ordered_ids, new_ids, is_new_id
    ordered_ids = [''];
    new_ids = [''];
    is_new_id = [''];
    global imgHeight, imgWidth
    framenum = -4
    print(cv2.CAP_PROP_FRAME_COUNT)
    
    while True:
        if "youtube" in video_path:
            ret, frame = cap.read(framenum + 4)  # for youtube video skip some frames
            framenum = cap.get(cv2.CAP_PROP_FRAME_COUNT)
        else:
            ret, frame = cap.read()

        # imgHeight, imgWidth, _ = frame.shape
        # frame = frame[1:round(imgHeight*0.5), 1:round(imgWidth*0.5)] # crop image
        # frame = frame[round(imgHeight*0.5):round(imgHeight), round(imgWidth*0.25):round(imgWidth*0.75)] # crop image

        if not ret:
            client.send_message('/multi_tracker_off')
            break

        # frame = cv2.resize(frame, fx=video_downscale, fy=video_downscale, dsize=None, interpolation=cv2.INTER_AREA)
        frame = cv2.resize(frame, None, fx = video_downscale, fy=video_downscale)
        imgHeight, imgWidth, _ = frame.shape
        # detect objects in the frame
        detections = detector.process_image(frame)

        # track detected objects
        _ = tracker.step(detections=detections)
        active_tracks = tracker.active_tracks(min_steps_alive=3)

        # visualize and show detections and tracks
        if show_detections:
            for det in detections:
                draw_detection(frame, det)
                # sending osc data
                # x,y = center(det.box,imgHeight,imgWidth)
                # client.send_message('/position', [x, y])

        for track in active_tracks:
            # draw_track(frame, track, thickness=2, text_at_bottom=True, text_verbose=track_text_verbose)
            draw_track(frame, track, thickness=2)

        # sort new and old ids, assigning a small positive number (their position in the ordered_ids list)
        new_ids = [track.id for track in active_tracks]
        ordered_ids = [ id if id in new_ids else '' for id in ordered_ids] # set '' to disappeared boxes (id)
        is_new_id = [0] * len(is_new_id)

        for id in new_ids:
            if id not in ordered_ids:
                if ordered_ids.count('') > 0:
                    is_new_id[ordered_ids.index('')] = 1
                    ordered_ids[ordered_ids.index('')] = id
                else:
                    is_new_id.append(1)
                    ordered_ids.append(id)

        # attr = [xy for det in active_tracks for xy in center(det.box,imgHeight,imgWidth)]
        # client.send_message('/active_tracks', [len(attr)] + attr )

        attr = [nxy for det in active_tracks for nxy in osc_message_boid(det)]
        print(attr)
        # [n1, bool1, x1, y1, n2, x2, y2, ...]
        client.send_message('/active_tracks', [len(active_tracks)] + attr )
        print([len(active_tracks)] + attr)



        cv2.imshow('frame', frame)
        c = cv2.waitKey(viz_wait_ms)
        if c == ord('q'):
            client.send_message('/multi_tracker_off')
            break
    



if __name__ == '__main__':
    fire.Fire(run)
