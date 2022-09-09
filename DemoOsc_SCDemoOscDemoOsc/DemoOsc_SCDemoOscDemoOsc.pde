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
boolean SCComActive = true;

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
  if (!faceRecognitionActive) {  // manually control first boid if no face tracking is present
    face_x = mouseX;
    face_y = mouseY;
  }

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
    flock = new Flock();
    group = 0;
    color c = paletteGenerator();
    PVector t;
    t = new PVector(random(0, width), random(0, height));
    flock.addBoid(new Boid(mouseX, mouseY, group, c, t));
    group++;
  }
}

void keyPressed() {
  if (key == 'r') {
    flock.randomize();
  } else {
    for (Boid b : flock.boids) {
      switch(key) {
      case 'w':
        b.maxspeed = b.maxspeed+0.05;
        break;
      case 'q':
        b.maxspeed = b.maxspeed-0.05;
        break;
      case 'a':
        b.maxforce = b.maxforce-0.008 * 0.05;
        break;
      case 's':
        b.maxforce = b.maxforce+0.008 * 0.05;
        break;
      }
    }
    // print
    if (key == 'p') {
      print("\n\n");
      print("\nmax force: ", flock.boids.get(0).maxforce);
      print("\nmaxspeed:  ", flock.boids.get(0).maxspeed);
      print("\n");
      delay(500);
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
    int python_webcam_dimension = 1;
    face_x = width-theOscMessage.get(0).floatValue()/python_webcam_dimension*width;
    face_y = theOscMessage.get(1).floatValue()/python_webcam_dimension*height;
    print("osc message from python", face_x, face_y);
  }

  if (theOscMessage.checkAddrPattern("/active_tracks")==true) { 
    faceRecognitionActive = true;

    int n_tracks = theOscMessage.get(0).intValue();
    ArrayList<Integer> groups_list = new ArrayList<Integer>();
    ArrayList<float[]> xy_list = new ArrayList<float[]>();

    for (int i=0; i < n_tracks; i++) {
      groups_list.add(theOscMessage.get(i*3+1).intValue());
      float[] xy = {theOscMessage.get(i*3+2).floatValue() * width, theOscMessage.get(i*3+3).floatValue() * height};
      xy_list.add(xy);
    }
    // eventyually convert to array, but list is more convenient
    //Integer[] groups = new Integer[groups_list.size()];
    //groups = groups_list.toArray(groups);

    flock.move_targets(groups_list, xy_list);
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
