import ch.bildspur.postfx.builder.*;
import ch.bildspur.postfx.pass.*;
import ch.bildspur.postfx.*;
PostFX fx;

int group;
Flock flock;

float maxDist;
PVector R, L;

int Nparticles = 1;
float MASS_TO_PIXEL = 1E-4;
float G = 6.67 * 1E-11;

void setup() {
  noCursor();
  colorMode(HSB, 255);
  size(1200, 800, P2D);
  fx = new PostFX(this);
  fx.preload(BloomPass.class);
  fx.preload(BlurPass.class);
  
  flock = new Flock();
  float x, y;
  int count;
  color c;
  PVector t;
  for(group = 0 ;group < 100; group++){
    x = random(50, width-50);
    y = random(50, height-50);
    c = paletteGenerator();
    count = poisson(4);
      for (int i = 0; i < count; i++) {
        t = new PVector(random(0, width), random(0,height));
        flock.addBoid(new Boid(x+random(-45,45), y+random(-45,45), group, c, t));
      }
  }
  for(int p = 0; p < Nparticles; p++){
    flock.addStar();
  }
  
  maxDist = sqrt(pow(width,2)+pow(height,2));
  L = new PVector(-width*0.01, -height*0.01);
  R = new PVector(width*1.01, -height*0.01);

}

void draw() {
  colorMode(HSB, 255);
  background(0);
  flock.run();
  fx.render().bloom(0.1, 100, 10).blur(10, 100).compose();
}

// Add a new boid into the System
void mousePressed() {
  int count = poisson(3);
  color c = paletteGenerator();
  float x = mouseX;
  float y = mouseY;
  PVector t;
  for (int i = 0; i < count; i++) {
    t = new PVector(random(0, width), random(0,height));
    flock.addBoid(new Boid(x+random(-50,50), y+random(-50,50), group, c, t));
  }
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
