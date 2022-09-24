class Executor {

  int current_state; // boid index
  PVector position;
  int number;
  boolean isActive;
  float life;
  Boid boid;


  Executor(int number) {
    this.number = number;
  }

  void render() {
    // print executor
      if (clock_active) {
      stroke(#00ff00, 255);
      fill(255, 0);
      //ellipse(flock.boids.get(current_state).position.x, flock.boids.get(current_state).position.y, 10, 10);
      ellipse(boid.position.x, boid.position.y, 10*(number+1), 10*(number+1));
    }
  }
  
  void init(){
    
  }
}
