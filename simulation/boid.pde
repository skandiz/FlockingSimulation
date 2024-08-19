class Boid {
  int ID;
  PVector position;
  PVector velocity;
  PVector acceleration;
  float x, y, z;
  float r;
  float maxForce = 0.08;
  float maxSpeed = 4;
  float sc = 3;
  color col;
  float cohesionRadius, alignmentRadius, separationRadius;
  float n_c, n_a, n_s;
  OcTree octree, otherOctree;
  
  Cube wall;
  

  Boid(color col_, float cohesionRadius_, float alignmentRadius_, float separationRadius_, Cube wall_, int ID_) {
    this.wall = wall_;
    this.ID = ID_;
    this.position = new PVector(random(wall.x - 400, wall.x + 400),
      random(wall.y - 400, wall.y + 400),
      random(wall.z - 400, wall.z + 400) );

    if (obstacleVerb) {
      this.position = new PVector(random(wall.xMin, wall.xMax),
        random(wall.yMin, wall.yMax),
        random(wall.zMin, wall.zMin + 500) );
    }
    
    this.x = this.position.x;
    this.y = this.position.y;
    this.z = this.position.z;
    this.velocity = PVector.random3D().setMag(random(1, 2));
    this.acceleration = new PVector(0, 0, 0);
    this.col = col_;
    this.cohesionRadius = cohesionRadius_;
    this.alignmentRadius = alignmentRadius_;
    this.separationRadius = separationRadius_;
  }
  
  PVector avoid(PVector target, boolean weight) {
    PVector steer = new PVector(); //creates vector for steering
    steer.set(PVector.sub(position, target)); //steering vector points away from target
    if (weight)
      steer.mult(1/(pow(PVector.dist(position, target), 2)));
    return steer;
  }

  ArrayList<PVector> behaviour(OcTree octree, OcTree otherOctree) {
    float maxAngle = 3*PI/4 ;
    float tau;
    float v_0 = 2;
    this.n_c = 0;
    this.n_a = 0;
    this.n_s = 0;
    int interTot = 0;
    int avoidTot = 0;
    ArrayList<PVector> steering = new ArrayList<PVector>();
    PVector d_ci = new PVector();
    PVector d_si = new PVector();
    PVector d_ai = new PVector();
    PVector alignSteering = new PVector();
    PVector cohesionSteering = new PVector();
    PVector separationSteering = new PVector();
    PVector cruiseSteering = new PVector();
    PVector pitchSteering = new PVector();
    PVector noiseSteering = new PVector();
    
    PVector interSeparationSteering = new PVector();
    PVector avoidSteering = new PVector();
    
    
    if (this.cohesionRadius > this.alignmentRadius) this.r = cohesionRadius;
    else this.r = this.alignmentRadius;
        
    Cube range = new Cube(this.position.x, this.position.y, this.position.z, r);
    ArrayList<TreeItem> maybeNeighbors = octree.query(range, null);
    
    for (TreeItem other : maybeNeighbors) {
      
      if (this.ID == 0){
        other.boid.col = #FFF303;
      }
      
      PVector r_ij = PVector.sub(other.boid.position, this.position);
      float d = r_ij.mag();
      float theta = PVector.angleBetween(this.velocity, r_ij);
      
      if (other.boid != this && d < cohesionRadius && theta < maxAngle) {
        d_ci.add(r_ij.div(d));
        this.n_c++;
      }
      
      if (other.boid != this && d < alignmentRadius && theta < PI/4 + PI/8 && theta > PI/8)  {
        d_ai.add(other.boid.velocity.div(other.boid.velocity.mag()));
        this.n_a++;
      }
      
      if (other.boid != this && d < separationRadius) {
        d_si.add(r_ij.div(pow(d, 2)));
        this.n_s++;
      }
    }
    
    
    // IMPLEMENT SEPARATION BETWEEN SPECIES
    if (twoSpecies) {
      ArrayList<TreeItem> interMaybeNeighbors = otherOctree.query(range, null);
      for (TreeItem other : interMaybeNeighbors) {
        PVector diff = PVector.sub(this.position, other.boid.position);
        float d = diff.mag();
        float theta = PVector.angleBetween(this.velocity, diff);

        if (other.boid != this && d < interPerceptionRadius && theta < maxAngle) {
          diff.setMag(1/pow(d, 2)); // Magnitude inversely proportional to the squared distance
          interSeparationSteering.add(diff);
          interTot++;
        }
      }
    }
    
    // IMPLEMENT OBSTALCE AVOIDANCE
    if (obstacleVerb) {
      ObstacleCube obstacleRange = new ObstacleCube(this.position.x, this.position.y, this.position.z, cohesionRadius);
      ArrayList<ObstacleTreeItem> obstacles = obstacleOcTree.query(obstacleRange, null);
      for (ObstacleTreeItem p : obstacles) {
        PVector point = new PVector(p.x, p.y, p.z);
        PVector diff = PVector.sub(this.position, point);
        float d = diff.mag();
        float theta = PVector.angleBetween(this.velocity, diff);

        if (d < cohesionRadius && theta < maxAngle) {
          diff.setMag(1/pow(d, 2)); // Magnitude inversely proportional to the squared distance
          avoidSteering.add(diff);
          avoidTot++;
        }
      }
    }
    
    // ALIGNMENT STEERING
    if (this.n_a > 0) {
      d_ai.div(this.n_a);
      alignSteering = d_ai.sub(this.velocity.div(this.velocity.mag()));
      alignSteering.mult(alignMultiplier);
    }
    steering.add(alignSteering);
    
    // COHESION STEERING
    if (this.n_c > 0 ) {
      d_ci.div(this.n_c);
      cohesionSteering = d_ci.div(d_ci.mag());
      cohesionSteering.mult(cohesionMultiplier);
    }
    steering.add(cohesionSteering);
    
    // UPDATE COHESION & ALIGNMENT RADIUS 
    /*
    if (this.ID == 0 && !recordData ) { //&& millis() - prevTime >= 1000
      println("n_c: ", n_c, "cohesion radius: ", this.cohesionRadius, "n_a: ", n_a, "alignment radius: ", this.alignmentRadius, "perception radius: ", r);
      //prevTime = millis();
    }
    */
    this.cohesionRadius = max(this.separationRadius, (1 - 0.01) * this.cohesionRadius + 0.01 * (rMax - 15*n_c));
    this.alignmentRadius = max(this.separationRadius, (1 - 0.01) * this.alignmentRadius + 0.01 * (rMax - 15*n_a));
    
    // SEPARATION STEERING
    if (this.n_s > 0){
      d_si.div(this.n_s);
      d_si.mult(-1);
      separationSteering = d_si.div(d_si.mag());
      separationSteering.mult(separationMultiplier);
    }
    steering.add(separationSteering);
    
    // CRUISE SPEED STEERING
    if (v_0 > this.velocity.mag()){
      tau = 1;
    }
    else {
      tau = 2;
    }    
    cruiseSteering = this.velocity.div(this.velocity.mag()).mult( v_0 - this.velocity.mag()).mult(tau);
    steering.add(cruiseSteering);
    
    // PITCH & ROLL STABILIZATION STEERING
    PVector z = new PVector(0, 0, 1);
    pitchSteering = z.mult(-pitchMultiplier*(this.velocity.div(this.velocity.mag())).dot(z)) ;
    steering.add(pitchSteering);
    
    /*
    rollSteering = 
    steering.add(rollSteering);
    */
    
    // NOISE STEERING
    noiseSteering = PVector.random3D().setMag(noiseMultiplier);
    steering.add(noiseSteering);
    
    // INTER-SPECIES STEERING
    if (twoSpecies && interTot > 0) {
      interSeparationSteering.div(interTot);
      interSeparationSteering.setMag(this.maxSpeed);
      interSeparationSteering.sub(this.velocity);
      interSeparationSteering.limit(this.maxForce);
    }
    if (twoSpecies) steering.add(interSeparationSteering.mult(2));
    
    // OBSTACLE AVOIDANCE STEERING
    if (obstacleVerb && avoidTot > 0) {
      avoidSteering.div(avoidTot);
      avoidSteering.setMag(this.maxSpeed);
      avoidSteering.sub(this.velocity);
      avoidSteering.limit(this.maxForce);
    }
    if (obstacleVerb) steering.add(avoidSteering.mult(5));
    
    return steering;
  }

  void flock(OcTree octree, OcTree otherOctree) {
    ArrayList<PVector> steering = behaviour(octree, otherOctree);
    this.acceleration.add(steering.get(0)); // align steering force
    this.acceleration.add(steering.get(1)); // cohesion steering force
    this.acceleration.add(steering.get(2)); // separation steering force
    this.acceleration.add(steering.get(3)); // cruise steering force
    this.acceleration.add(steering.get(4)); // pitch steering force
    this.acceleration.add(steering.get(5)); // noise steering force
    
    if (twoSpecies) this.acceleration.add(steering.get(6)); // inter separation steering force
    if (twoSpecies && obstacleVerb) this.acceleration.add(steering.get(7));
    if (!twoSpecies && obstacleVerb) this.acceleration.add(steering.get(6));
    
    if (avoidWalls)
    {
      this.acceleration.add(PVector.mult(avoid(new PVector(this.position.x, wall.yMax, this.position.z), true), wallMultiplier));
      this.acceleration.add(PVector.mult(avoid(new PVector(this.position.x, wall.yMin, this.position.z), true), wallMultiplier));
    
      this.acceleration.add(PVector.mult(avoid(new PVector(wall.xMax, this.position.y, this.position.z), true), wallMultiplier));
      this.acceleration.add(PVector.mult(avoid(new PVector(wall.xMin, this.position.y, this.position.z), true), wallMultiplier));
      
      this.acceleration.add(PVector.mult(avoid(new PVector(this.position.x, this.position.y, wall.zMax), true), wallMultiplier));
      this.acceleration.add(PVector.mult(avoid(new PVector(this.position.x, this.position.y, wall.zMin), true), wallMultiplier));
    }
    this.acceleration.limit(maxForce);
  }
  
  
  void run(OcTree octree, OcTree otherOctree) {
    flock(octree, otherOctree);
    edges();
    show();
  }

  void update() {
    velocity.add(acceleration);
    //velocity.limit(maxSpeed);
    position.add(velocity);
    // RESET FORCES
    acceleration.mult(0);
  }

  void edges() {
    if (!avoidWalls){
      if (position.x > wall.xMax) {
        position.x = wall.xMin;
      } else if (position.x < wall.xMin) {
        position.x = wall.xMax;
      }
      if (position.y > wall.yMax) {
        position.y = wall.yMin;
  
      } else if (position.y < wall.yMin) {
        position.y = wall.yMax;
      }
      if (position.z > wall.zMax) {
        position.z = wall.zMin;
        
      } else if (position.z < wall.zMin) {
        position.z = wall.zMax;
      }
    }
    if (avoidWalls){
      if (position.x > wall.xMax || position.x < wall.xMin || position.y > wall.yMax || position.y < wall.yMin || position.z > wall.zMax || position.z < wall.zMin) {
        println("Edge error");  
        exit(); 
      }
    }
  }
  
  

  void show() {
    stroke(this.col);
    if (this.ID == 0) {
      stroke(#FFF303);
      
    }
    strokeWeight(3);

    pushMatrix();
    translate(position.x, position.y, position.z);
    rotateY(atan2(-velocity.z, velocity.x));
    rotateZ(asin(velocity.y/velocity.mag()));

    strokeWeight(.1);
    noStroke();
    fill(col);
    if (this.ID == 0) {
      fill(#FFF303);
      
    }

    //draw bird
    beginShape(TRIANGLES);
    vertex(3*sc, 0, 0);
    vertex(-3*sc, 2*sc, 0);
    vertex(-3*sc, -2*sc, 0);

    vertex(3*sc, 0, 0);
    vertex(-3*sc, 2*sc, 0);
    vertex(-3*sc, 0, 2*sc);

    vertex(3*sc, 0, 0);
    vertex(-3*sc, 0, 2*sc);
    vertex(-3*sc, -2*sc, 0);

    vertex(-3*sc, 0, 2*sc);
    vertex(-3*sc, 2*sc, 0);
    vertex(-3*sc, -2*sc, 0);
    endShape();
    popMatrix();
  }
}
