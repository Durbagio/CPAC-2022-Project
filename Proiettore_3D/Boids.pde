float step = 5.0; // random walker step
int maxCount = 5;

// The Boid class

class Boid {

  PVector position;
  PVector velocity;
  PVector acceleration;
  float r;
  float maxforce;    // Maximum steering force
  float maxspeed;    // Maximum speed
  int group;
  PVector target;
  float humanization;

    Boid(float x, float y, int g, PVector t) {
    acceleration = new PVector(0, 0);

    float angle = random(TWO_PI);
    velocity = new PVector(cos(angle), sin(angle));

    position = new PVector(x, y);
    
    r = 5.0;
    
    maxspeed = 0.3;
    maxforce = 0.008;
    
    group = g;
    
    target = t;
    
    humanization = random(0.5,1.5);
  }

  void run(ArrayList<Boid> boids) {
    flock(boids);
    update();
    borders();
    render(boids);
  }

  void applyForce(PVector force) {
    // We could add mass here if we want A = F / M
    acceleration.add(force);
  }

  // We accumulate a new acceleration each time based on three rules
  void flock(ArrayList<Boid> boids) {
    PVector sep = separate(boids);   // Separation
    PVector ali = align(boids);      // Alignment
    PVector coh = cohesion(boids);   // Cohesion
    PVector walk = walker();        // Target
    // Arbitrarily weight these forces
    sep.mult(1.5*humanization);
    ali.mult(1.0*humanization);
    coh.mult(1.0*humanization);
    walk.mult(3.0*humanization);
    // Add the force vectors to acceleration
    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
    applyForce(walk);
  }

  // Method to update position
  void update() {
    // Update velocity
    velocity.add(acceleration);
    // Limit speed
    velocity.limit(maxspeed);
    position.add(velocity);
    // Reset accelertion to 0 each cycle
    acceleration.mult(0);
  }

  // A method that calculates and applies a steering force towards a target
  // STEER = DESIRED MINUS VELOCITY
  PVector seek(PVector target) {
    PVector desired = PVector.sub(target, position);  // A vector pointing from the position to the target
    // Scale to maximum speed
    desired.normalize();
    desired.mult(maxspeed);

    // Steering = Desired minus Velocity
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxforce);  // Limit to maximum steering force
    return steer;
  }

  void render(ArrayList<Boid> boids) {
    colorMode(RGB, 255);
    stroke(255);
    strokeWeight(1);
    strokeCap(ROUND);
    line(position.x, HEIGHT/2, position.y, position.x, HEIGHT/2-HEAD, position.y);

    colorMode(HSB, 255);
    stroke(world);
    strokeWeight(r);
    point(position.x, -HEIGHT/2, position.y);
    
    // POSITION TRACKING
    float dist;
    PVector pos = new PVector(position.x, -HEIGHT/2, position.y);
    strokeWeight(0.5);

    dist = PVector.dist(FR, pos);
    stroke(world, 100*pow((MAXDIST-dist+HEIGHT)/MAXDIST, 4));
    line(FR.x, FR.y, FR.z, pos.x, pos.y, pos.z);
    
    dist = PVector.dist(BR, pos);
    stroke(world, 100*pow((MAXDIST-dist+HEIGHT)/MAXDIST, 4));
    line(BR.x, BR.y, BR.z, pos.x, pos.y, pos.z);
    
    dist = PVector.dist(FL, pos);
    stroke(world, 100*pow((MAXDIST-dist+HEIGHT)/MAXDIST, 4));
    line(FL.x, FL.y, FL.z, pos.x, pos.y, pos.z);
    
    dist = PVector.dist(BL, pos);
    stroke(world, 100*pow((MAXDIST-dist+HEIGHT)/MAXDIST, 4));
    line(BL.x, BL.y, BL.z, pos.x, pos.y, pos.z);

    //NEIGHBOURING LINES
    for (Boid other:  boids){ 
      float d = PVector.dist(position, other.position);
      int count = 0;
      if ((d > 0) && (d < 60.0) && (count < maxCount)){
        stroke(world, 255*pow((60-d)/60, 0.8));
        strokeWeight(1);
        line(position.x, -HEIGHT/2, position.y, other.position.x, -HEIGHT/2, other.position.y);
        count++;
      }
    }
  }

  // Wraparound
  //void borders() {
  //  if (position.x < -r) position.x = SIDE/2+r;
  //  if (position.y < -r) position.y = SIDE/2+r;
  //  if (position.x > SIDE/2+r) position.x = -r;
  //  if (position.y > SIDE/2+r) position.y = -r;
  //}
  
  //Reflect
  void borders() {
    if (position.x < -SIDE/2+r*2) velocity.x = -velocity.x;
    if (position.y < -SIDE/2+r*2) velocity.y = -velocity.y;
    if (position.x > SIDE/2-r*2) velocity.x = -velocity.x;
    if (position.y > SIDE/2-r*2) velocity.y = -velocity.y;
  }

  // Separation
  // Method checks for nearby boids and steers away
  PVector separate (ArrayList<Boid> boids) {
    float desiredseparation = 30.0f;
    PVector steer = new PVector(0, 0, 0);
    int count = 0;
    // For every boid in the system, check if it's too close
    for (Boid other : boids) {
      float d = PVector.dist(position, other.position);
      // If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
      if ((d > 0) && (d < desiredseparation)) {
        // Calculate vector pointing away from neighbor
        PVector diff = PVector.sub(position, other.position);
        diff.normalize();
        diff.div(pow(d, 2));        // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
      }
    }
    // Average -- divide by how many
    if (count > 0) {
      steer.div((float)count);
    }

    // As long as the vector is greater than 0
    if (steer.mag() > 0) {

      // Implement Reynolds: Steering = Desired - Velocity
      steer.normalize();
      steer.mult(maxspeed);
      steer.sub(velocity);
      steer.limit(maxforce);
    }
    return steer;
  }

  // Alignment
  // For every nearby boid in the system, calculate the average velocity
  PVector align (ArrayList<Boid> boids) {
    PVector sum = new PVector(0, 0);
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (group == other.group)) {
        sum.add(other.velocity);
        count++;
      }
    }
    if (count > 0) {
      sum.div((float)count);

      // Implement Reynolds: Steering = Desired - Velocity
      sum.normalize();
      sum.mult(maxspeed);
      PVector steer = PVector.sub(sum, velocity);
      steer.limit(maxforce);
      return steer;
    } 
    else {
      return new PVector(0, 0);
    }
  }

  // Cohesion
  // For the average position (i.e. center) of all nearby boids, calculate steering vector towards that position
  PVector cohesion (ArrayList<Boid> boids) {
    PVector sum = new PVector(0, 0);   // Start with empty vector to accumulate all positions
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (group == other.group)) {
        sum.add(other.position); // Add position
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      return seek(sum);  // Steer towards the position
    } 
    else {
      return new PVector(0, 0);
    }
  }
    
  // Target
  // For the group target position, calculate steering vector towards that position
  PVector walker() {
    PVector steer = seek(target);
    steer.normalize();
    steer.mult(maxspeed);
    steer.sub(velocity);
    steer.limit(maxforce);
    
    target.x = target.x + random(-step, step);
    target.y = target.y + random(-step, step);
    if (target.x < -SIDE/2+r*2) target.x = -SIDE/2-target.x;
    if (target.y < -SIDE/2+r*2) target.y = -SIDE/2-target.y;
    if (target.x > SIDE/2-r*2) target.x = SIDE/2-target.x;
    if (target.y > SIDE/2-r*2) target.y = SIDE/2-target.y;
    
    return steer;
  }
}
