// The Flock (a list of Boid objects)
int N;

class Flock {
  ArrayList<Boid> boids; // An ArrayList for all the boids
  ArrayList<ArrayList<Float>> distances;
  int current_state;
  int current_state2;
  int manual_boid_group;
  ArrayList<Boid> deadBoids; // separate arraylist for boids that implement the fade out effect

  Flock() {
    boids = new ArrayList<Boid>(); // Initialize the ArrayList
    distances = new ArrayList<ArrayList<Float>>();
    deadBoids = new ArrayList<Boid>();
    current_state = 0;
    current_state2 = 0;
  }


  // todo: add infinite threshold for inactive boids; or use different approach: new boids
  synchronized void run() {
    if (manual_control || faceRecognitionActive) {
      if (manual_control) {
        for (Boid b : boids) {
          if (b.index == manual_boid_group) b.target = new PVector(mouseX, mouseY);
        }
        //boids.get(0).target = new PVector(mouseX, mouseY);
      } else {
        boids.get(0).position = new PVector(face_x, face_y);
      }
    }
    compute_markov_matrix();
    // Passing the entire list of boids to each boid individually
    for (Boid b : boids) {
      if (b.life > 0) b.run(boids, distances); // skip computation for dead boids: todo: maybe improve
    }

    //dead boids
    ArrayList<Boid> all_boids = new ArrayList<Boid>();
    all_boids.addAll(deadBoids);
    all_boids.addAll(boids);
    //println(deadBoids.size());
    //for (int i = 0; i < deadBoids.size(); i++) {
    for (int i = deadBoids.size()-1; i >= 0; i--) {
      //print("here");
      all_boids.get(i).render(all_boids, i);
      all_boids.get(i).decrease_life();
      if ( deadBoids.get(i).life == 0 ) deadBoids.remove(i);
    }

    for (int i = N-1; i > 0; i--) {
      // leave at least one boid
      if (boids.get(i).life == 0 )  removeBoid(i);
    }

    //render the playing boid...
    if (clock_active && boids.size()>0) {
      stroke(#00ff00, 255);
      fill(255, 0);
      ellipse(boids.get(current_state).position.x, boids.get(current_state).position.y, 10, 10);
    }
    if (clock_2_active && boids.size()>0) {
      stroke(#ffff00, 255);
      fill(255, 0);
      ellipse(boids.get(current_state2).position.x, boids.get(current_state2).position.y, 15, 15);
    }
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

  void addDeadBoid(PVector position) {
    group = 0;
    color c = paletteGenerator();
    Boid b = new Boid(position.x, position.y, group, c, position);
    b.is_active = false;
    b.is_fixed = true;
    b.life = 2;
    deadBoids.add(b);
  }

  // todo: somewere treat the index changing and current_state 
  synchronized void removeBoid(int index) {
    //int N_old = boids.size();
    boids.remove(index);
    // update the distances matrix dimensions
    distances.remove(index); // remove last row
    for (ArrayList<Float> row : distances) { // remove last colum (each entry of row)
      row.remove(index);
    }
    // shift indexes
    for (int i = index; i < boids.size(); i++) boids.get(i).index = i;
  }

  // old function: maitained for backward compatibility
  void computeMarkovMsg(OscMessage m, int currentState) {
    float[][] probMatrix;
    float[] probs;
    N = boids.size();
    probMatrix = new float [N][N];
    for (int i = 0; i < N; i++) {
      float sum = 0;
      for (int j = 0; j < N; j++) {
        sum = sum + (thresh - min(thresh, distances.get(i).get(j)))/thresh;
      }
      for (int j = 0; j < N; j++) {
        float value = (thresh - min(thresh, distances.get(i).get(j)))/thresh;
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

  //////////////////////////////////////////////////////////////////
  // overload the function
  public OscMessage computeMarkovMsg() {
    OscMessage m = new OscMessage("/probability");
    float[] probs = new float[boids.size()];
    float[] values = new float[boids.size()];
    float sum = 0;
    float cont = 0;
    // todo: add execution objects, or variables in this function (eg. an arraylist of integer?, or matrix
    // todo: enucleate this function (also in the flock.run() )
    for (int j = 0; j < N; j++) {
      values[j] = (thresh - min(thresh, distances.get(current_state).get(j)))/thresh;
      if (values[j] > 0) cont++;
    }
    if (N > 1 && cont > 1) values[current_state] = 0;
    for (int j = 0; j < N; j++) {
      sum = sum + values[j];
    }
    
    for (int j = 0; j < N; j++) {
      probs[j] = values[j]/sum;
    }

    current_state = wchoose(probs);
    m.add(nomalize_curr_state(current_state, probs));

    printArray(probs);
    //println(current_state);

    return m;
  }

  // todo: unire queste due funzioni
  public OscMessage computeMarkovMsg2() {
    OscMessage m = new OscMessage("/probability2");
    float[] probs = new float[boids.size()];
    float[] values = new float[boids.size()];
    float sum = 0;
    float cont = 0;
    // todo: add execution objects, or variables in this function (eg. an arraylist of integer?, or matrix
    // todo: enucleate this function (also in the flock.run() )
    for (int j = 0; j < N; j++) {
      values[j] = (thresh - min(thresh, distances.get(current_state).get(j)))/thresh;
      if (values[j] > 0) cont++;
    }
    if (N > 1 && cont == 1) values[current_state] = 0;
    for (int j = 0; j < N; j++) {
      sum = sum + values[j];
    }
    
    for (int j = 0; j < N; j++) {
      probs[j] = values[j]/sum;
    }
    
    for (int j = 0; j < N; j++) {
      probs[j] = values[j]/sum;
    }
    current_state2 = wchoose(probs);
    m.add(nomalize_curr_state(current_state2, probs));
    
    //printArray(probs);
    //println(current_state2);
    
    return m;
  }

  void move_group_target(int group, float x, float y) {
    for (Boid b : boids) {
      if (b.group == group) {
        b.set_target(x, y);
      }
    }
  }

  // this function is executed each time an OscMessage is received from python
  synchronized void move_targets(ArrayList<Integer> groups, ArrayList<float[]> xy_list, ArrayList<Boolean> is_new_id) {
    // update all current existing boids:
    ArrayList<Integer> existing_groups = new ArrayList<Integer>();
    //for (Boid b : boids) {
    for (int i = boids.size()-1; i >= 0; i--) {
      Boid b = boids.get(i);
      existing_groups.add(b.group);
      if ( groups.contains(b.group) ) {
        b.set_target( xy_list.get(groups.indexOf(b.group)) );
        b.is_active = true;
        if ( is_new_id.get(groups.indexOf(b.group)) ) {
          addDeadBoid(b.position); // for fade out effect

          // fade in effect, for the boid in the new position
          b.life = 1e-4; // eps
          // for faster convergence change also the position... maybe remove for smoother effect.
          b.position = ( new PVector( xy_list.get(groups.indexOf(b.group))[0], xy_list.get(groups.indexOf(b.group))[1] ));
        }
      } else {
        addDeadBoid(b.position);
        removeBoid(b.index);
        //b.is_active = false;
      }
    }

    // create new boids if necessary
    for (int g : groups) {
      if ( !existing_groups.contains(g) ) {
        float x = xy_list.get(groups.indexOf(g))[0];
        float y = xy_list.get(groups.indexOf(g))[1];
        PVector target = new PVector( x, y );
        Boid b = new Boid(x, y, g, paletteGenerator(), target);
        b.life = 1e-4; // eps
        addBoid(b);
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

  void compute_markov_matrix() {
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
  }

  /*
  void computeBPMMsg(OscMessage m) {
   N = boids.size();
   float BPM = 10 * N;
   m.add(BPM);
   }
   */
}

// wheighted random choose of vector element
public int wchoose(float[] probs) {
  double p = random(1);
  double cumulativeProbability = 0.0;
  for (int i = 0; i < probs.length; i++) {
    cumulativeProbability += probs[i];
    if (p <= cumulativeProbability) {
      return i;
    }
  }
  // this should never be reached
  print("WARNING: check the probability distribution vector (must be < 1)");
  return -1;
}

// format the state to facilitate PD state manage
// convert the index to normalize to the goup size
public int[] nomalize_curr_state(int current_state, float[] probs) {
  int nonNull_index = 0, nonNull_count = 0;
  for (int i = 0; i < probs.length; i++) {
    if (i == current_state) nonNull_index = nonNull_count;
    if (probs[i] > 0) nonNull_count++;
  }
  if (probs.length != 1) nonNull_count = nonNull_count + 1; 
  //return new int[]  {(nonNull_index % 10)+1, nonNull_count};
  return new int[]  {current_state + 1, nonNull_count};
}
