// The Flock (a list of Boid objects) //<>//
int N;

class Flock {
  ArrayList<Boid> boids; // An ArrayList for all the boids
  ArrayList<ArrayList<Float>> distances;
  int current_state;
  int current_state2;
  int manual_boid_group;
  ArrayList<Cluster> clusters;
  ArrayList<Executor> executors;
  ArrayList<Integer> playing_executors;
  ArrayList<Integer> paused_executors;
  ArrayList<Boid> deadBoids; // separate arraylist for boids that implement the fade out effect
  String text;

  Flock() {
    boids = new ArrayList<Boid>(); // Initialize the ArrayList
    distances = new ArrayList<ArrayList<Float>>();
    deadBoids = new ArrayList<Boid>();
    clusters = new ArrayList<Cluster>();
    //clusters.add(new Cluster(clusters.size())); // at lest one group
    current_state = 0;
    current_state2 = 0;
    playing_executors = new ArrayList<Integer>();
    paused_executors = new ArrayList<Integer>();
    executors = new ArrayList<Executor>();
    for (int i = 0; i < max_number_executors; i++) {
      executors.add(new Executor(i));
      paused_executors.add(i);
    }
    text = "";
  }


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
    update_distance_matrix();
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

    // clear dead boids
    for (int i = N-1; i > 0; i--) {
      // leave at least one boid
      if (boids.get(i).life == 0 )  removeBoid(i);
    }

    //render the playing boid...
    //if (clock_active && boids.size()>0) {
    //  stroke(#00ff00, 255);
    //  fill(255, 0);
    //  ellipse(boids.get(current_state).position.x, boids.get(current_state).position.y, 10, 10);
    //}
    //if (clock_2_active && boids.size()>0) {
    //  stroke(#ffff00, 255);
    //  fill(255, 0);
    //  ellipse(boids.get(current_state2).position.x, boids.get(current_state2).position.y, 15, 15);
    //}
    for ( int i : playing_executors ) if (executor_visualization)  executors.get(i).render();

    // group info visualization
    fill(255);
    textSize(50);
    text(count_connected_groups(distances), 10, 50);
    textSize(30);
    connectedComponents();
    text(text, 10, 80);
    //printArray(groups);  
    //for (Cluster g : clusters) {
    //  println(g);
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

  void addDeadBoid(PVector position) {
    group = 0;
    color c = paletteGenerator();
    Boid b = new Boid(position.x, position.y, group, c, position);
    b.is_active = false;
    b.is_fixed = true;
    b.life = 1;
    b.lifetime = 1;
    deadBoids.add(b);
  }

  // todo: somewere treat the index changing and current_state
  synchronized void removeBoid(int index) {
    // check if it's playing and eventually change execution boid
    for ( Executor e : executors) if (boids.get(index).equals(e.boid)) force_execution_transition(e.number);
    //int N_old = boids.size();
    boids.remove(index);
    // update the distances matrix dimensions
    distances.remove(index);
    for (ArrayList<Float> row : distances) {
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

  synchronized public OscMessage computeMarkovMsg(int executor_index) {
    OscMessage m = new OscMessage("/probability" + executor_index);
    float[] probs = new float[boids.size()];

    float sum = 0;
    for (int j = 0; j < N; j++) {
      sum = sum + (thresh - min(thresh, distances.get(executors.get(executor_index).boid.index).get(j)))/thresh;
    }
    for (int j = 0; j < N; j++) {
      float value = (thresh - min(thresh, distances.get(executors.get(executor_index).boid.index).get(j)))/thresh;
      probs[j] = value/sum;
    }

    // todo: merge claudio's code

    //executors.get(executor_index).current_state = wchoose(probs);
    //executors.get(executor_index).boid = boids.get(executors.get(executor_index).current_state);

    executors.get(executor_index).boid = boids.get(wchoose(probs));

    //if (executors.get(executor_index).current_state != executors.get(executor_index).boid.index ) {
    //  println("current state" + executors.get(executor_index).current_state);
    //  println("boid_state" + executors.get(executor_index).current_state);
    //  pause();
    //}

    // format the state to facilitate PD state manage
    // convert the index to normalize to the goup size
    int nonNull_index = 0, nonNull_count = 0;
    for (int i = 0; i < probs.length; i++) {
      if ( i == executors.get(executor_index).current_state) nonNull_index = nonNull_count;
      if (probs[i] > 0) nonNull_count++;
    }
    
    // handle executors on the same boid
    for ( int i = playing_executors.size()-1; i >=0 ; i--) {
      int other_index = playing_executors.get(i);
      if (other_index != executor_index && playing_executors.contains(executor_index)) {
        // cycle through every other playng_executor the playing_executors index array
        if (executors.get(executor_index).boid.equals(executors.get(other_index).boid)) { // if two boids coincide
        // retain the younger one (playing_executors is a kind of FIFO)
          if (playing_executors.indexOf(executor_index) < playing_executors.indexOf(other_index)){ // executor_index is older
            println(playing_executors);
            println(executor_index);
            paused_executors.add(paused_executors.size(), playing_executors.remove(playing_executors.indexOf(executor_index))); // -> remove it
            m.add(0); // means this player has to stop
            break;
          }else{
            paused_executors.add(paused_executors.size(), playing_executors.remove(playing_executors.indexOf(other_index)));
          }
        }
      }
    }

    //m.add( (nonNull_index % 10) + 1 );                    // normalized version
    m.add(executors.get(executor_index).current_state + 1); // absolute version
    m.add(nonNull_count);

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
  // this function modify the boids arraylist, but keeps their indexes consistent with the order in the array
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
          for ( Executor e : executors) if (b.equals(e.boid)) force_execution_transition(e.number);

          // fade in effect, for the boid in the new position
          b.life = 1e-4; // eps
          b.position = ( new PVector( xy_list.get(groups.indexOf(b.group))[0], xy_list.get(groups.indexOf(b.group))[1] ));
        }
      } else {
        addDeadBoid(b.position);
        removeBoid(b.index);
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

  void force_execution_transition(int index) {
    executors.get(index).boid = boids.get(find_closest_boid(executors.get(index).boid.position));
    // todo: capire se aggiungere un osc message, forse anche no
  }

  // move all boids to a random position
  void randomize() {
    for ( Boid b : boids ) {
      PVector position = new PVector(random(0, width), random(0, height));
      b.position = position;
    }
  }

  void update_distance_matrix() {
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

  // find closest boid, but ensure is not the same
  public int find_closest_boid(PVector position) { 
    float[] distances = new float[flock.boids.size()];
    int index_min = 0;
    for (int i = 0; i < distances.length; i++) {
      distances[i] = PVector.dist(flock.boids.get(i).position, position);
      if (distances[i] < distances[index_min] && distances[i] > 0) index_min = i;
    }
    return flock.boids.get(index_min).index;
  }

  //////////////////    group counter    /////////////////
  public void connectedComponents() {
    if ( N > 1 ) {
      text = "";
      // Mark all the vertices as not visited
      N = flock.boids.size();
      boolean[] visited = new boolean[N];
      int group_count = -1;
      int number_old_clusters = clusters.size();
      for ( Cluster c : clusters) {
        c.boids_indexes.clear();
      }
      for (int v = 0; v < N; ++v) {
        if (!visited[v]) {
          // print all reachable vertices
          // from v
          group_count++;
          if ( clusters.size() <= group_count ) {
            clusters.add(new Cluster(clusters.size()));
          }
          text = text + "group " + group_count + ": ";
          DFSUtil(v, visited, group_count);
          text = text + "\n";
          //System.out.println();
        }
      }
      // filter cluster list
      //clusters.removeIf(new Predicate<Cluster>() {
      //  boolean test(Cluster cluster) {
      //    return cluster.boids_indexes.isEmpty();
      //  }
      //});
      for ( int i = clusters.size()-1; i >= 0; i--) {
        if ( clusters.get(i).boids_indexes.isEmpty()) clusters.remove(i);
      }

      int number_new_cluster =  clusters.size() - number_old_clusters;
      if (number_new_cluster > 0) { // cluster increase
        //println("group_count" + group_count);
        for (int i = 0; i < number_new_cluster; i++) {
          //print(i);
          // if executors are avaiables shift them to playng queue
          if (paused_executors.size() > 0 ) {
            playing_executors.add(playing_executors.size(), paused_executors.remove(0));

            /////////////////debug
            //println("playing_executors" + playing_executors.toString());
            //println("paused_executors" + paused_executors.toString());
            ////executors.get(playing_executors.get(0)).current_state = clusters.get(playing_executors.get(0)).get_random_index(); // da errore
            //println(playing_executors.get(0)); // index of just added executor
            //println(clusters.get(playing_executors.get(0)));
            //for (Cluster g : clusters) {
            //  println(g);
            //}
            //print( clusters.get(number_old_clusters + i).get_random_index() );
            ////////////// end debug

            executors.get(playing_executors.get(playing_executors.size()-1)).boid = boids.get( clusters.get(number_old_clusters + i).get_random_index() );
          }
        }
        text = text + playing_executors.toString();
      }
    }
  }

  // Depth First Search
  void DFSUtil(int v, boolean[] visited, int group_count) {
    // Mark the current node as visited and print it
    visited[v] = true;
    //System.out.print(v + " ");
    text = text + v + " ";
    clusters.get(group_count).boids_indexes.add(v);
    // Recur for all the vertices
    // adjacent to this vertex
    for (int i = 0; i < N; i++) {
      if (distances.get(v).get(i) < thresh ) {
        // is connected
        if (!visited[i]) {
          DFSUtil(i, visited, group_count);
        }
      }
    }
  }
}

///////// Additional functions

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


// requirement: the matrix is guaranteed to describe transitive connectivity
int count_connected_groups(ArrayList<ArrayList<Float>> distances) {
  int n = distances.size();
  int[] nodes_to_check = new int[n];
  for (int i = 0; i < n; i++) {
    nodes_to_check[i] = i;
  }
  int count = 0;
  while (n > 0) {
    count++;
    n--; 
    int node = nodes_to_check[n];
    ArrayList<Float> adjacent = distances.get(node);
    int i = 0;
    while (i < n) {
      int other_node = nodes_to_check[i];
      if (adjacent.get(other_node) < thresh) {
        // is connected
        n--;
        nodes_to_check[i] = nodes_to_check[n];
      } else {
        i++;
      }
    }
  }
  return count;
}
