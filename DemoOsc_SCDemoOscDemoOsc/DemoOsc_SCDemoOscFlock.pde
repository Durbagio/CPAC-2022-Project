// The Flock (a list of Boid objects)
int N;

class Flock {
  ArrayList<Boid> boids; // An ArrayList for all the boids
  ArrayList<ArrayList<Float>> distances;
  
  Flock() {
    boids = new ArrayList<Boid>(); // Initialize the ArrayList
    distances = new ArrayList<ArrayList<Float>>();
  }

  void run() {
    // calculate the distance triangular matrix
    N = boids.size();
    for(int i = 0; i < N; i++)  {
      for(int j = 0; j < i; j++){
       float d = PVector.dist(boids.get(i).position, boids.get(j).position);
       distances.get(i).set(j, d);
      }
      // elemento sulla diagonale (distanza da se stesso = 0)
      distances.get(i).set(i, 0.0);
    }
    // transform the matrices into simmetric ones
    for(int i = 0; i< N; i++){
      for(int j = i+1; j < N; j++){
        distances.get(i).set(j, distances.get(j).get(i));
      }
    }
    // Passing the entire list of boids to each boid individually
    for (Boid b : boids) {
      if(b.group!=0){
        b.run(boids, distances);
      }else{ // human point is controlled by the detected face position
        b.position = new PVector(face_x,face_y);
        b.render(boids, distances);
      }
    }
  }

  void addBoid(Boid b) {
    // add the new boid to the list
    b.index = boids.size();
    boids.add(b);
    // update the distances matrix dimensions
    N = boids.size();
    ArrayList<Float> column = new ArrayList<Float>();
    for(int i = 0; i < N; i++) {
      column.add(0.0);
    }
    distances.add(column);
    for(int i = 0; i < N-1; i++)  {
      distances.get(i).add(0.0);
    }
  }

  void computeMsg(OscMessage m) {
    N = boids.size();
    for(int i = 0; i < N; i++)  {
      float sum = 0;
       for(int j = 0; j < N; j++){
       sum = sum + distances.get(i).get(j);
      }
      for(int j = 0; j < N; j++){
        float value =  distances.get(i).get(j);
        if (sum > 0) m.add(value/sum);
        else m.add(1.0);
      }
    }
  }
}
