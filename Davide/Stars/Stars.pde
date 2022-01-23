import ch.bildspur.postfx.builder.*;
import ch.bildspur.postfx.pass.*;
import ch.bildspur.postfx.*;

PostFX fx;
PGraphics blooming;

StarSystem S;
int Nparticles = 250;
float MASS_TO_PIXEL = 1E-4;
float G = 6.67 * 1E-11;
float c = 0.1; //drag coeff

void setup(){
  colorMode(HSB, 255);
  size(800, 600, P2D);
  fx = new PostFX(this);
  fx.preload(BloomPass.class);
  fx.preload(BlurPass.class);
  
  S = new StarSystem();
  for(int p = 0; p < Nparticles; p++){
    S.origin = new PVector(random(0, width), random(0, height));
    S.addStar();
  }
   
  background(0);
}

void draw(){
  background(0);
  S.draw();
  fx.render().bloom(0.1, 100, 10).blur(10, 100).compose();
}
