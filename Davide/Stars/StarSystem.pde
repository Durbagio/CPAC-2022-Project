class StarSystem{
  PVector origin;
  ArrayList<Star> stars;
  Attractor A;
  
  StarSystem(){
    this.origin=new PVector(0, 0);
    this.stars = new ArrayList<Star>();
    this.A = new Attractor();
  }

  void addStar(){
    this.origin = new PVector(random(0, width), random(0, height));
    this.stars.add(new Star(this.origin, random(1.0, 5.0), random(10, 100)));   
  }
  void addStar(PVector pos, PVector force, float radius){
    this.origin = pos.copy();
    this.origin.x = this.origin.x + random(-5, 5);
    this.origin.y = this.origin.y + random(-5, 5);
    this.stars.add(new Star(this.origin, radius, random(10, 20), force));   
  }
  
  void draw() {
    Star s;
    for(int i=this.stars.size()-1; i>=0; i--){
      s=this.stars.get(i);
      s.draw();
      if(s.isDead()){
        if(!s.burning) this.addStar();
         stars.remove(i);
      }
    }
    A.draw(stars); 
  }

}
