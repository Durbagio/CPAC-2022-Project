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

// for osc receive
float face_x,face_y;
boolean faceRecognitionActive = false;
boolean SCComActive = true;

float tresh = 500.0;

void setup() {
  //size(1280,720,P2D);
  fullScreen(P2D);
  fx = new PostFX(this);
  fx.preload(BloomPass.class);
  fx.preload(BlurPass.class);
  
  flock = new Flock();
  float x, y;
  
  color c;
  PVector t;
  for(group = 0 ;group < 4; group++){
    x = random(50, width-50);
    y = random(50, height-50);
    c = paletteGenerator();
    //count = poisson(4);
    count = 1;
      for (int i = 0; i < count; i++) {
        t = new PVector(random(0, width), random(0,height));
        flock.addBoid(new Boid(x+random(-45,45), y+random(-45,45), group, c, t));
      }
  }
  
  oscP5 = new OscP5(this, 3000);  // incoming osc messages OSC PORT = 3000
  myRemoteLocation = new NetAddress("127.0.0.1", 57120);

}

void draw() {
  if(!faceRecognitionActive){  // manually control first boid if no face tracking is present
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
  int count = poisson(4);
  //int count = 1;
  color c = paletteGenerator();
  float x = mouseX;
  float y = mouseY;
  PVector t;
  for (int i = 0; i < count; i++) {
    t = new PVector(random(0, width), random(0,height));
    flock.addBoid(new Boid(x+random(-50,50), y+random(-50,50), group, c, t));
  }
  print(flock.boids.size()+"\n");
  group++;
}

color paletteGenerator() {
  colorMode(HSB, 100);  // Use HSB with scale of 0-100
  color randomColor = color(int(random(0, 100)), 100, 100);
  colorMode(RGB,255);
  
  return randomColor;
}

int poisson(int mean) {

  double L = exp(-mean);
  int k=0;
  double p = random(0,1);
  
  while(p > L) {
    p = p * random(0,1);
    k++;
  } 
  
  return k+1;
}


void oscEvent(OscMessage theOscMessage) {
  if(theOscMessage.checkAddrPattern("/position")==true) {
    faceRecognitionActive = true;
    int python_webcam_dimension = 300;
    face_x = width-theOscMessage.get(0).floatValue()/python_webcam_dimension*width;
    face_y = theOscMessage.get(1).floatValue()/python_webcam_dimension*height;
    print("osc message from python" , face_x, face_y);
   }
   
  if(theOscMessage.checkAddrPattern("/clock")==true) {
    int currentState = theOscMessage.get(0).intValue();
    SCComActive = true;
    print("osc message from SC, current state: " , currentState);
    
    OscMessage MarkovMsg = new OscMessage("/markov");
    //OscMessage BPMMsg = new OscMessage("/BPM"); 
    flock.computeMarkovMsg(MarkovMsg, currentState);
  
    oscP5.send(MarkovMsg, myRemoteLocation);
  
    MarkovMsg.print();
    print("\n");
    
   }
}
