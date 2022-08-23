class Flock {
    ArrayList<Boid> boids; 
    color col;
    float cohesionRadius, alignmentRadius, separationRadius;
    
    Flock(color col_, float cohesionRadius_, float aligmentRadius_, float separationRadius_) {
        this.cohesionRadius = cohesionRadius_;
        this.alignmentRadius = aligmentRadius_;
        this.separationRadius = separationRadius_;
        this.col = col_;
        this.boids = new ArrayList<Boid>(); 
        // BOIDS INITIALIZATION
        for (int i = 0; i < boyz_num; i++){
           boids.add(new Boid(col, cohesionRadius, alignmentRadius, separationRadius, wall, i));
        }
    }
    
    void run(OcTree octree, OcTree otherOctree) { 
        // UPDATE OCTREE
        
        if (octreeShow) octree.show(col, 1);
        
        // UPDATE BOIDS
        
        for (Boid b : boids) {
            b.run(octree, otherOctree);
        }

    }
    
    void update(){
      for (Boid b : boids) {
        b.update();
      }
    }
}
