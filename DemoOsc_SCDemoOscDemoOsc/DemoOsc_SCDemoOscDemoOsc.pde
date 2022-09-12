import ch.bildspur.postfx.builder.*;
import ch.bildspur.postfx.pass.*;
import ch.bildspur.postfx.*;
PostFX fx;

import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

int group, count;
Flock flock;

// osc receive
float face_x, face_y;
boolean faceRecognitionActive = false;
boolean multiObjectTrackingActive = false;
boolean manual_control = false;
boolean SCComActive = true;
boolean double_draw = false;
boolean kill = false;
int render_target = 0;


float tresh = 500.0;

void setup() {
  size(1280, 720, P2D);
  //fullScreen(P2D);
  fx = new PostFX(this);
  fx.preload(BloomPass.class);
  fx.preload(BlurPass.class);

  flock = new Flock();
  float x, y;

  color c;
  PVector t;
  for (group = 0; group < 4; group++) {
    x = random(50, width-50);
    y = random(50, height-50);
    c = paletteGenerator();
    //count = poisson(4);
    count = 1;
    for (int i = 0; i < count; i++) {
      t = new PVector(random(0, width), random(0, height));
      flock.addBoid(new Boid(x+random(-45, 45), y+random(-45, 45), group, c, t));
    }
  }

  oscP5 = new OscP5(this, 3000);  // incoming osc messages OSC PORT = 3000
  myRemoteLocation = new NetAddress("127.0.0.1", 57120);
}

void draw() {
  background(0);
  colorMode(RGB, 255);
  flock.run();

  fx.render().bloom(0.1, 100, 10).compose();
}

// Add a new boid into the System
void mousePressed() {
  if (mouseButton == LEFT) {
    int count = poisson(4);
    //int count = 1;
    color c = paletteGenerator();
    float x = mouseX;
    float y = mouseY;
    PVector t;
    for (int i = 0; i < count; i++) {
      t = new PVector(random(0, width), random(0, height));
      flock.addBoid(new Boid(x+random(-50, 50), y+random(-50, 50), group, c, t));
    }
    print(flock.boids.size()+"\n");
    group++;
  } else {
    // restart
    // throw away all boids and create only one
    flock = new Flock();
    group = 0;
    color c = paletteGenerator();
    PVector t;
    t = new PVector(random(0, width), random(0, height));
    flock.addBoid(new Boid(mouseX, mouseY, group, c, t));
    group++;

    faceRecognitionActive = false;
    manual_control = false;
    multiObjectTrackingActive = false;
  }
}

void keyPressed() {
  switch(key) {
  case 'x':
    double_draw = !double_draw;
    break;
  case 'm':
    manual_control = !manual_control;
    break;
  case 'k':
    kill = true;
    break;
  case 'r':
    flock.randomize();
    break;
  case 't':
    render_target = (render_target + 1) % 3;
    break;
  case 'p':
    print("\n\n");
    print("\nmax force: ", flock.boids.get(0).maxforce);
    print("\nmaxspeed:  ", flock.boids.get(0).maxspeed);
    print("\nmanual  :  ", manual_control);
    print("\nframerate: ",frameRate);
    print("\n");
    delay(500);
    break;
  }

  // keys that need iteration for each boids
  for (Boid b : flock.boids) {
    switch(key) {
    case 'w':
      b.maxspeed = flock.boids.get(0).maxspeed+0.05;
      break;
    case 'q':
      b.maxspeed = flock.boids.get(0).maxspeed-0.05;
      break;
    case 'a':
      b.maxforce = flock.boids.get(0).maxforce-0.008 * 0.05;
      break;
    case 's':
      b.maxforce = flock.boids.get(0).maxforce+0.008 * 0.05;
      break;
    }
  }
}

color paletteGenerator() {
  colorMode(HSB, 100);  // Use HSB with scale of 0-100
  color randomColor = color(int(random(0, 100)), 100, 100);
  colorMode(RGB, 255);

  return randomColor;
}

int poisson(int mean) {

  double L = exp(-mean);
  int k=0;
  double p = random(0, 1);

  while (p > L) {
    p = p * random(0, 1);
    k++;
  } 

  return k+1;
}


void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("/position")==true) {
    faceRecognitionActive = true;
    int python_webcam_dimension = 300;
    face_x = width-theOscMessage.get(0).floatValue()/python_webcam_dimension*width;
    face_y = theOscMessage.get(1).floatValue()/python_webcam_dimension*height;
    print("osc message from python", face_x, face_y);
  }

  if (theOscMessage.checkAddrPattern("/active_tracks")==true) { 
    multiObjectTrackingActive = true;

    int n_tracks = theOscMessage.get(0).intValue();
    ArrayList<Integer> groups_list = new ArrayList<Integer>();
    ArrayList<Boolean> is_new_id = new ArrayList<Boolean>();
    ArrayList<float[]> xy_list = new ArrayList<float[]>();


    for (int i=0; i < n_tracks; i++) {
      groups_list.add(theOscMessage.get(i*4+1).intValue());
      is_new_id.add(theOscMessage.get(i*4+2).intValue()==1);
      float[] xy = {theOscMessage.get(i*4+3).floatValue() * width, theOscMessage.get(i*4+4).floatValue() * height};
      xy_list.add(xy);
    }
    // eventyually convert to array, but list is more convenient
    //Integer[] groups = new Integer[groups_list.size()];
    //groups = groups_list.toArray(groups);

    flock.move_targets(groups_list, xy_list, is_new_id);
  }

  if (theOscMessage.checkAddrPattern("/clock")==true) {
    int currentState = theOscMessage.get(0).intValue();
    SCComActive = true;
    print("osc message from SC, current state: ", currentState);

    OscMessage MarkovMsg = new OscMessage("/markov");
    //OscMessage BPMMsg = new OscMessage("/BPM");
    flock.computeMarkovMsg(MarkovMsg, currentState);

    oscP5.send(MarkovMsg, myRemoteLocation);

    MarkovMsg.print();
    print("\n");
  }
}
