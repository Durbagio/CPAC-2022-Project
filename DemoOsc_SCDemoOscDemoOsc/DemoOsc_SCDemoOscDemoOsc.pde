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
boolean double_draw = false;
int render_target = 0;

// moving boids playing 60 bpm: simulate pure data /clock message
boolean clock_active = false;
boolean clock_2_active = false;
boolean internal_clock = true;
int timer = 0 ; 

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

  if ( internal_clock && clock_active && (millis() - timer >= 1000)) {
    flock.computeMarkovMsg();
    if (clock_2_active) flock.computeMarkovMsg2(); // second executor
    timer = millis();
  }
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
  } else { // RIGHT button
    // restart
    // throw away all boids and create only one
    flock = new Flock();
    group = 0;
    color c = paletteGenerator();
    PVector t;
    t = new PVector(random(0, width), random(0, height));
    //flock.addBoid(new Boid(mouseX, mouseY, group, c, t));
    //group++;
    clock_active = false;
    clock_2_active = false;
    flock.current_state = 0;
    flock.current_state2 = 0;

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
  case 'm': // manual control (drag boid)
    // find closest boid
    float[] distances = new float[flock.boids.size()];
    int index_min = 0;
    for (int i = 0; i < distances.length; i++) {
      distances[i] = PVector.dist(flock.boids.get(i).position, new PVector(mouseX, mouseY)); // skip computation for dead boids: todo: improve
      if (distances[i] < distances[index_min]) index_min = i;
    }
    flock.manual_boid_group = flock.boids.get(index_min).index;
    manual_control = !manual_control;
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
    print("\nframerate: ", frameRate);
    print("\nflocksize: ", flock.boids.size());
    print("\n");
    //looping = !looping; // (un)freeze the execution
    delay(1000);
    break;
  case 'f':
    group = max(200, group+1); // just set an offset to avoid interference with other boids 
    Boid b = new Boid(group);
    b.is_fixed = true;
    flock.addBoid(b);
    break;
  case 'c':
    clock_active = ! clock_active;
    break;
  case 'e':
    group = max(200, group+1); // just set an offset to avoid interference with other boids 
    Boid b2 = new Boid(group);
    b2.is_fixed = true;
    flock.addBoid(b2);
    flock.current_state2 = flock.boids.size()-1;
    clock_2_active = true;
    break;
  }

  // keys that need iteration for each boids
  for (Boid b : flock.boids) {
    switch(key) {
    case 'w':
      b.maxspeed = flock.boids.get(0).maxspeed+0.25;
      break;
    case 'q':
      b.maxspeed = flock.boids.get(0).maxspeed-0.25;
      break;
    case 'a':
      b.maxforce = flock.boids.get(0).maxforce-0.008 * 0.3;
      break;
    case 's':
      b.maxforce = flock.boids.get(0).maxforce+0.008 * 0.3;
      break;
    case 'k': // kill
      b.is_active = false;
      clock_active = false;
      flock.current_state = 0;
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

  if (theOscMessage.checkAddrPattern("/multi_tracker_off")==true) {
    multiObjectTrackingActive = false;
    print("multi obj track off");
  }

  if (theOscMessage.checkAddrPattern("/active_tracks")==true) { 
    multiObjectTrackingActive = true;

    int n_tracks = theOscMessage.get(0).intValue();
    ArrayList<Integer> groups_list = new ArrayList<Integer>();
    ArrayList<Boolean> is_new_id = new ArrayList<Boolean>();
    ArrayList<float[]> xy_list = new ArrayList<float[]>();


    for (int i=0; i < n_tracks; i++) {
      groups_list.add(theOscMessage.get(i*4+1).intValue() + 1);  // note: this + 1 offset allows to have group 0 boids that 
      //allow implementation of fade out effect of dead detected track ids  
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
    print("osc message from SC, current state: ", currentState);

    OscMessage MarkovMsg = new OscMessage("/markov");
    //OscMessage BPMMsg = new OscMessage("/BPM");
    flock.computeMarkovMsg(MarkovMsg, currentState);

    oscP5.send(MarkovMsg, myRemoteLocation);

    MarkovMsg.print();
    print("\n");
  }

  if (theOscMessage.checkAddrPattern("/new_clock")==true) {
    internal_clock = false; // stop internal metronome
    // we could also join the two 
    oscP5.send(flock.computeMarkovMsg(), myRemoteLocation);
  }
  
  if (theOscMessage.checkAddrPattern("/new_clock2")==true) {
    internal_clock = false;
    oscP5.send(flock.computeMarkovMsg2(), myRemoteLocation);
  }
}
