// The Flock (a list of Boid objects)

class Flock {
  ArrayList<Boid> boids; // An ArrayList for all the boids
  ArrayList<Star> stars; // An ArrayList for all the stars

  Flock() {
    boids = new ArrayList<Boid>(); // Initialize the ArrayList
    stars = new ArrayList<Star>();
  }

  void run() {
    for (Boid b : boids) {
      b.run(boids, stars);  // Passing the entire list of boids to each boid individually
    }
    Star s;
    for(int i=this.stars.size()-1; i>=0; i--){
      s=this.stars.get(i);
      s.draw();
      if(s.isDead()){
         stars.remove(i);
         this.addStar();
      }
    }
  }

  void addBoid(Boid b) {
    boids.add(b);
  }
  
  void addStar(){
    PVector origin = new PVector(random(0, width), random(0, height));
    this.stars.add(new Star(origin, random(1.0, 5.0), random(10, 100)));   
  }

}
