import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

int group;
Flock flock;

float tresh = 200.0;

void setup() {
  size(640, 480);
  flock = new Flock();
  float x, y;
  
  color c;
  PVector t;
  for(group = 0 ;group < 15; group++){
    x = random(50, width-50);
    y = random(50, height-50);
    c = paletteGenerator();
    count = poisson(4);
    //count = 1;
      for (int i = 0; i < count; i++) {
        t = new PVector(random(0, width), random(0,height));
        flock.addBoid(new Boid(x+random(-45,45), y+random(-45,45), group, c, t));
      }
  }
  
  oscP5 = new OscP5(this, 3000);
  myRemoteLocation = new NetAddress("127.0.0.1", 57120);
}

void draw() {
  background(0);
  colorMode(RGB, 255);
  flock.run();
  //print(flock.distanceMatrix());
  
  OscMessage testMsg = new OscMessage("/markov"); 
  flock.computeMsg(testMsg);
  //oscP5.send(testMsg, myRemoteLocation);
  testMsg.print();
  print("\n");
  
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
