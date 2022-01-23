// MANGIA STELLE (le attrae e le ingloba) => DIVENTA + GRANDE, + PESANTE
// BRUCIA STELLE (le genera con velocità inversamente proporzionale alla sua e in numero propozionale alla massa) => DIVENTA - GRANDE, - PESANTE 

class Attractor {
  PVector currPos, oldPos, currVel, oldVel, currAcc;
  float mass, radius;
  
  Attractor() {
    this.currPos = new PVector(mouseX, mouseY);
    this.oldPos = new PVector(mouseX, mouseY);
    this.currVel = new PVector(0,0);
    this.oldVel = new PVector(0,0);
    this.currAcc = new PVector(0,0);
    this.radius = 5.0;
    this.mass = pow(radius/MASS_TO_PIXEL, 2);
  }
  
  void update(ArrayList<Star> stars) {
    this.oldPos = this.currPos.copy();
    this.currPos.set(mouseX, mouseY);
    this.oldVel = this.currVel.copy();
    this.currVel = PVector.sub(oldPos, currPos);
    this.currAcc = PVector.sub(oldVel, currVel);
    this.radius = sqrt(this.mass)*MASS_TO_PIXEL;
    
    eat(stars);
    burn();
  }
  
  void eat(ArrayList<Star> stars) {
    PVector force = new PVector();
    for (Star s : stars) {
      float dist = PVector.dist(this.currPos, s.pos);
      if (dist > this.radius) {
        force  = this.currPos.copy();
        force.sub(s.pos);
        force.normalize(); 
        force.mult(s.mass*this.mass*G/pow(dist,2));
        s.applyForce(force);
      }
      else {
        this.mass = this.mass + s.mass;
        s.health = 0;
      }
    }
  }
  
  void burn() {
    PVector force = this.currVel.copy();
    force.mult(this.mass*1E-5);
    for (int i =0; i < floor(this.currVel.mag()); i++) {
      float radius = random(1.0, 5.0);
      S.addStar(this.currPos, force, radius);
      //this.mass = this.mass - pow(radius/MASS_TO_PIXEL, 2);
    }
}
  
  void draw(ArrayList<Star> stars) {
    update(stars);
    fill(255);
    noStroke();
    ellipse(currPos.x, currPos.y, radius, radius);
  }
  
}
