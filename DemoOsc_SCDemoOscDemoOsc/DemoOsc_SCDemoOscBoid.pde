float step = 5.0; // random walker step
int maxCount = 25;
// The Boid class

class Boid {

  PVector position;
  PVector velocity;
  PVector acceleration;
  float r;
  float maxforce;    // Maximum steering force
  float maxspeed;    // Maximum speed
  int group, index;
  color groupColor;
  PVector target;
  float humanization;

  Boid(float x, float y, int g, color c, PVector t) {
    acceleration = new PVector(0, 0);

    float angle = random(TWO_PI);
    velocity = new PVector(cos(angle), sin(angle));

    position = new PVector(x, y);

    r = 1.0;

    maxspeed = 0.3;
    maxforce = 0.008;

    group = g;
    groupColor = c;

    target = t;

    humanization = random(0.5, 1.5);
  }

  void run(ArrayList<Boid> boids, ArrayList<ArrayList<Float>> dist) {
    flock(boids, dist); // compute force
    update();           // move boid
    borders();
    render(boids, dist);
  }

  void applyForce(PVector force) {
    // We could add mass here if we want A = F / M
    acceleration.add(force);
  }

  // We accumulate a new acceleration each time based on three rules
  void flock(ArrayList<Boid> boids, ArrayList<ArrayList<Float>> dist) {
    PVector sep = separate(boids, dist);   // Separation
    PVector ali = align(boids, dist);      // Alignment
    PVector coh = cohesion(boids, dist);   // Cohesion
    PVector walk = walker();        // Target
    // Arbitrarily weight these forces
    sep.mult(1.5*humanization);
    ali.mult(1.0*humanization);
    coh.mult(2.0*humanization);
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
  // STEER = DESIRED - VELOCITY
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

  void render(ArrayList<Boid> boids, ArrayList<ArrayList<Float>> dist) {
    stroke(255);
    fill(255);
    int mul = 3;
    if (group==0) { // cange appearance for the human point
      stroke(#ffcc00);
      fill(#ffcc00);
      mul = 6;
    }
    ellipse(position.x, position.y, r*mul, r*mul);
    //print(position.x,position.y); // added for debugging
    int i, count = 0;
    float d, T=tresh/2;
    // distance for 0 to index
    for (i = 0; i < index; i++) {
      d = dist.get(index).get(i);
      if ((d > 0) && (d < T) && (count < maxCount)) {
        stroke(255, 255*pow((T-d)/T, 0.8));
        strokeWeight(1.5);
        line(position.x, position.y, boids.get(i).position.x, boids.get(i).position.y);
        count++;
      }
    }
    // distance for index to N
    for (i = boids.size()-1; i > index; i--) {
      d = dist.get(index).get(i);
      if ((d > 0) && (d < T) && (count < maxCount)) {
        stroke(255, 255*pow((T-d)/T, 0.8));
        strokeWeight(1.5);
        line(position.x, position.y, boids.get(i).position.x, boids.get(i).position.y);
        count++;
      }
    }
  }

  // Wraparound
  //void borders() {
  //  if (position.x < -r) position.x = width+r;
  //  if (position.y < -r) position.y = height+r;
  //  if (position.x > width+r) position.x = -r;
  //  if (position.y > height+r) position.y = -r;
  //}

  //Reflect
  void borders() {
    if (position.x < -r*2) velocity.x = -velocity.x;
    if (position.y < -r*2) velocity.y = -velocity.y;
    if (position.x > width+r*2) velocity.x = -velocity.x;
    if (position.y > height+r*2) velocity.y = -velocity.y;
  }

  // Separation
  // Method checks for nearby boids and steers away
  PVector separate (ArrayList<Boid> boids, ArrayList<ArrayList<Float>> dist) {
    float desiredseparation = 30.0f, d;
    PVector steer = new PVector(0, 0, 0);
    int count = 0, i;
    // For every boid in the system, check if it's too close
    // distance for 0 to index
    for (i = 0; i < index; i++) {
      d = dist.get(index).get(i);
      if ((d > 0) && (d < desiredseparation)) {
        // Calculate vector pointing away from neighbor
        PVector diff = PVector.sub(position, boids.get(i).position);
        diff.normalize();
        diff.div(pow(d, 2));        // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
      }
    }
    // distance for index to N
    for (i = boids.size()-1; i > index; i--) {
      d = dist.get(index).get(i);
      if ((d > 0) && (d < desiredseparation)) {
        // Calculate vector pointing away from neighbor
        PVector diff = PVector.sub(position, boids.get(i).position);
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
  PVector align (ArrayList<Boid> boids, ArrayList<ArrayList<Float>> dist) {
    PVector sum = new PVector(0, 0);
    int count = 0, i;
    float d;
    // Check distance from other boids
    // distance for 0 to index
    for (i = 0; i < index; i++) {
      d = dist.get(index).get(i);
      if ((d > 0) && (group == boids.get(i).group)) {
        sum.add(boids.get(i).velocity);
        count++;
      }
    }
    // distance for index to N
    for (i = boids.size()-1; i > index; i--) {
      d = dist.get(index).get(i);
      if ((d > 0) && (group == boids.get(i).group)) {
        sum.add(boids.get(i).velocity);
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
    } else {
      return new PVector(0, 0);
    }
  }

  // Cohesion
  // For the average position (i.e. center) of all nearby boids, calculate steering vector towards that position
  PVector cohesion (ArrayList<Boid> boids, ArrayList<ArrayList<Float>> dist) {
    PVector sum = new PVector(0, 0);   // Start with empty vector to accumulate all positions
    int count = 0, i;
    float d;
    // Check distance from other boids
    // distance for 0 to index
    for (i = 0; i < index; i++) {
      d = dist.get(index).get(i);
      if ((d > 0) && (group == boids.get(i).group)) {
        sum.add(boids.get(i).position);
        count++;
      }
    }
    // distance for index to N
    for (i = boids.size()-1; i > index; i--) {
      d = dist.get(index).get(i);
      if ((d > 0) && (group == boids.get(i).group)) {
        sum.add(boids.get(i).position);
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      return seek(sum);  // Steer towards the position
    } else {
      return new PVector(0, 0);
    }
  }

  // Target
  // For the group target position, calculate steering vector towards that position
  PVector walker() {
    if (!faceRecognitionActive) {
      move_target();
    }
    PVector steer = seek(target);
    steer.normalize();
    steer.mult(maxspeed);
    steer.sub(velocity);
    steer.limit(maxforce);
    return steer;
  }

  // randomly move target
  void move_target() {
    target.x = target.x + random(-step, step);
    target.y = target.y + random(-step, step);
    if (target.x < -r*2) target.x = width+r*2;
    if (target.y < -r*2) target.y = height+r*2;
    if (target.x > width+r*2) target.x = -r*2;
    if (target.y > height+r*2) target.y = -r*2;
  }

  // overload the function to move target in desired position
  void move_target(float x, float y) {
    target.x = x;
    target.y = y;
  }
  void move_target(float[] xy) {
    target.x = xy[0];
    target.y = xy[1];
  }
}
