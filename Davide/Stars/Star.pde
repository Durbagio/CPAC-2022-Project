// le stelle nascono randomicamente nello spazio, vengono attratte e bruciate, gestendo i valori di forza e health diversamente
class Star{
  PVector pos, vel, acc;
  float radius, mass, health, maxHealth;
  float hue;
  Boolean burning;
  
  Star(PVector p, float r, float h){
    this.pos = p.copy();
    this.vel = new PVector(0,0);
    this.acc = new PVector(0,0);
    this.radius = r;
    this.mass = pow(radius/MASS_TO_PIXEL*1E-2, 2);
    this.health = 0;
    this.maxHealth = h;
    this.hue = random(18, 48);
    this.burning = false;
  }
  Star(PVector p, float r, float h, PVector f){
    this.pos = p.copy();
    this.vel = new PVector(0,0);
    this.acc = new PVector(0,0);
    this.radius = r;
    this.mass = pow(radius/MASS_TO_PIXEL*1E-2, 2);
    this.health = h;
    this.maxHealth = h;
    this.hue = random(18, 48);
    this.burning = true;

    applyForce(f);
  }
  
  void update(){  
    PVector dragForce = drag();
    applyForce(dragForce);
    this.vel.add(this.acc);
    this.pos.add(this.vel);
    this.acc.mult(0);
    // qua si potrebbe mettere un Boolean per sapere quando sta bruciando e farla morire dopo un tot
    if((health < maxHealth) && !burning) {
      health = health + 0.05;
    } else {
      health = health - 0.05;
    }
  }
  
  void applyForce(PVector force){    
    force = force.div(this.mass);
    this.acc.add(force);
  }
  
  PVector drag () {
    float speed = this.vel.mag();
    float mag = c * pow(speed, 2);
    PVector f = this.vel.copy();
    f.mult(-1);   
    f.setMag(mag);
    return f;
  }

  void draw(){
    update();
    fill(hue, 255, 255, 255*health/2/maxHealth);
    noStroke();
    ellipse(this.pos.x, this.pos.y, this.radius, this.radius); 
    blendMode(ADD);
    fill(255, 255*health/2/maxHealth);
    noStroke();
    ellipse(this.pos.x, this.pos.y, this.radius/2, this.radius/2); 
  }

  boolean isDead(){
    return this.health <= 0;
  }
}
