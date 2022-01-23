Flock flock;

float TIME;
float SIDE;
float HEIGHT;
float MAXDIST;
float HEAD;
PVector FR, BR, FL, BL;
PShape ROOM;
color world;
float inclination = PI/10;

void setup() {
  size(1000, 800, P3D);
  background(0);
  
  TIME = 0;
  SIDE = width/2;
  HEIGHT = height/3;
  HEAD = height*0.05;
  FR = new PVector(SIDE/2, HEIGHT/2-HEAD, SIDE/2);
  FL = new PVector(-SIDE/2, HEIGHT/2-HEAD, SIDE/2);
  BR = new PVector(SIDE/2, HEIGHT/2-HEAD, -SIDE/2);
  BL = new PVector(-SIDE/2, HEIGHT/2-HEAD, -SIDE/2);
  MAXDIST = sqrt(pow(HEIGHT,2)+2*pow(SIDE,2));
  
  colorMode(HSB, 255);
  world = color(0, 255, 255);
  
  createRoom();
  
  flock = new Flock();
  float x, y;
  int count;
  PVector t;
  for(int group = 0 ;group < 15; group++){
    x = random(-SIDE/2+50, SIDE/2-50);
    y = random(-SIDE/2+50, SIDE/2-50);
    count = poisson(4);
      for (int i = 0; i < count; i++) {
        t = new PVector(random(-SIDE/2, SIDE/2), random(-SIDE/2, SIDE/2));
        flock.addBoid(new Boid(x+random(-45,45), y+random(-45,45), group, t));
      }
  }
  
}

void draw() {
  colorMode(HSB, 255);
  background(0);

  translate(width/2, height/2, -50);
  shape(ROOM, 0, 0);
  ROOM.rotateY(PI/2000);
  rotateY(TIME*PI/2000);
  rotateX(inclination);

  stroke(world);
  strokeWeight(3);
  point(FR.x, FR.y, FR.z);
  point(FL.x, FL.y, FL.z);
  point(BR.x, BR.y, BR.z);
  point(BL.x, BL.y, BL.z);
  
  flock.run();
  
  TIME = TIME + 1;
  
  //world = color(255*sin(TIME/2000.0), 255, 255);
  ROOM.getChild(0).setStroke(world);
  
}

void createRoom () {
  ROOM = createShape(GROUP);
  
  PShape face = createShape();
  face.beginShape();
  colorMode(HSB, 255);
  face.noFill();
  face.stroke(world, 100);
  face.strokeWeight(1);
  face.vertex(0, 0, 0);
  face.vertex(SIDE, 0, 0);
  face.vertex(SIDE, 0, SIDE);
  face.vertex(0, 0, SIDE);
  face.vertex(0, 0, 0);
  face.endShape();
  ROOM.addChild(face);
  
  face = createShape();
  face.beginShape();
  colorMode(HSB, 255);
  face.noFill();
  face.stroke(255, 100);
  face.strokeWeight(3);
  face.vertex(0, HEIGHT, 0);
  face.vertex(SIDE, HEIGHT, 0);
  face.vertex(SIDE, HEIGHT, SIDE);
  face.vertex(0, HEIGHT, SIDE);
  face.vertex(0, HEIGHT, 0);
  face.endShape();
  ROOM.addChild(face);
  
  //face = createShape();
  //face.beginShape();
  //face.noFill();
  //face.stroke(255, 100);
  //face.strokeWeight(1);
  //face.vertex(0, 0, 0);
  //face.vertex(0, HEIGHT, 0);
  //face.vertex(0, 0, 0);
  //face.endShape();
  //ROOM.addChild(face);
  
  //face = createShape();
  //face.beginShape();
  //face.noFill();
  //face.stroke(255, 100);
  //face.strokeWeight(1);
  //face.vertex(SIDE, 0, 0);
  //face.vertex(SIDE, HEIGHT, 0);
  //face.vertex(SIDE, 0, 0);
  //face.endShape();
  //ROOM.addChild(face);
  
  //face = createShape();
  //face.beginShape();
  //face.noFill();
  //face.stroke(255, 100);
  //face.strokeWeight(1);
  //face.vertex(SIDE, 0, SIDE);
  //face.vertex(SIDE, HEIGHT, SIDE);
  //face.vertex(SIDE, 0, SIDE);
  //face.endShape();
  //ROOM.addChild(face);
  
  //face = createShape();
  //face.beginShape();
  //face.noFill();
  //face.stroke(255, 100);
  //face.strokeWeight(1);
  //face.vertex(0, 0, SIDE);
  //face.vertex(0, HEIGHT, SIDE);
  //face.vertex(0, 0, SIDE);
  //face.endShape();
  //ROOM.addChild(face);

  ROOM.translate(-SIDE/2, -HEIGHT/2, -200);
  ROOM.rotateX(inclination);
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
