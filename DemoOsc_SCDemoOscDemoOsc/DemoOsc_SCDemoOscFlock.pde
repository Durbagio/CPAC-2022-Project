// The Flock (a list of Boid objects)
int N;

class Flock {
  ArrayList<Boid> boids; // An ArrayList for all the boids
  ArrayList<ArrayList<Float>> distances;

  Flock() {
    boids = new ArrayList<Boid>(); // Initialize the ArrayList
    distances = new ArrayList<ArrayList<Float>>();
  }

  synchronized void run() {
    if (manual_control || faceRecognitionActive) {
      if (manual_control) {
        for (Boid b : boids) {
          if (b.group == 100) b.run(boids, distances); // skip computation for dead boids: todo: improve
        }
        boids.get(0).target = new PVector(mouseX, mouseY);
      } else {
        boids.get(0).position = new PVector(face_x, face_y);
      }
    }
    // calculate the distance triangular matrix
    N = boids.size();
    for (int i = 0; i < N; i++) {
      for (int j = 0; j < i; j++) {
        float d = PVector.dist(boids.get(i).position, boids.get(j).position);
        distances.get(i).set(j, d);
      }
      // elemento sulla diagonale (distanza da se stesso = 0)
      distances.get(i).set(i, 0.0);
    }
    // transform the matrices into simmetric ones
    for (int i = 0; i< N; i++) {
      for (int j = i+1; j < N; j++) {
        distances.get(i).set(j, distances.get(j).get(i));
      }
    }
    // Passing the entire list of boids to each boid individually
    for (Boid b : boids) {
      if (b.life > 0) b.run(boids, distances); // skip computation for dead boids: todo: improve
    }

    //for (int i = N-1; i > 0; i--) {
    //  // leave at least one boid
    //  if (boids.get(i).life == 0 )  removeBoid(i);
    //}
  }


  synchronized void addBoid(Boid b) {
    //print(flock);
    // add the new boid to the list
    b.index = boids.size();
    boids.add(b);
    // update the distances matrix dimensions
    N = boids.size();
    ArrayList<Float> column = new ArrayList<Float>();
    for (int i = 0; i < N; i++) {
      column.add(0.0);
    }
    distances.add(column);
    for (int i = 0; i < N-1; i++) {
      distances.get(i).add(0.0);
    }
  }

  // overload function for simplicity
  void addDeadBoid(PVector position) {
    group = 0;
    color c = paletteGenerator();
    Boid b = new Boid(position.x, position.y, group, c, position);
    b.is_active = false;
    addBoid(b);
  }

  synchronized void removeBoid(int index) {
    //int N_old = boids.size();
    boids.remove(index);
    // update the distances matrix dimensions
    distances.remove(index); // remove last row
    for (ArrayList<Float> row : distances) { // remove last colum (each entry of row)
      row.remove(index);
    }
  }

  void computeMarkovMsg(OscMessage m, int currentState) {
    float[][] probMatrix;
    float[] probs;
    N = boids.size();
    probMatrix = new float [N][N];
    for (int i = 0; i < N; i++) {
      float sum = 0;
      for (int j = 0; j < N; j++) {
        sum = sum + (tresh - min(tresh, distances.get(i).get(j)))/tresh;
      }
      for (int j = 0; j < N; j++) {
        float value = (tresh - min(tresh, distances.get(i).get(j)))/tresh;
        probMatrix[i][j] = value/sum;
        //m.add(value/sum);
        //m.add(probMatrix[i][j]);
      }
    }

    //We find the row of the current state and choose to next state based on its probabilites
    probs = probMatrix[currentState];
    for (int i = 0; i < probs.length; i++) {
      m.add(probs[i]);
    }
  }

  void move_group_target(int group, float x, float y) {
    for (Boid b : boids) {
      if (b.group == group) {
        b.set_target(x, y);
      }
    }
  }

  // this function is executed each time an OscMessage is received from python
  void move_targets(ArrayList<Integer> groups, ArrayList<float[]> xy_list, ArrayList<Boolean> is_new_id) {
    // update all current existing boids:
    ArrayList<Integer> existing_groups = new ArrayList<Integer>();
    for (Boid b : boids) {
      existing_groups.add(b.group);
      if ( groups.contains(b.group) ) {
        b.set_target( xy_list.get(groups.indexOf(b.group)) );
        b.is_active = true;
        if ( is_new_id.get(groups.indexOf(b.group)) ) {
          //addDeadBoid(b.position); // for fade out effect
          // fade in effect, for the boid in the new position
          b.life = 1e-4; // eps
          // for faster convergence change also the position... maybe remove for smoother effect.
          b.position = ( new PVector( xy_list.get(groups.indexOf(b.group))[0], xy_list.get(groups.indexOf(b.group))[1] ));
        }
      } else {
        b.is_active = false;
      }
    }

    // create new boids if necessary
    for (int g : groups) {
      if ( !existing_groups.contains(g) ) {
        float x = xy_list.get(groups.indexOf(g))[0];
        float y = xy_list.get(groups.indexOf(g))[1];
        PVector target = new PVector( x, y );
        addBoid(new Boid(x, y, g, paletteGenerator(), target));
      }
    }
  }

  // move all boids to a random position
  void randomize() {
    for ( Boid b : boids ) {
      PVector position = new PVector(random(0, width), random(0, height));
      b.position = position;
    }
  }


  /*
  void computeBPMMsg(OscMessage m) {
   N = boids.size();
   float BPM = 10 * N;
   m.add(BPM);
   }
   */
}
