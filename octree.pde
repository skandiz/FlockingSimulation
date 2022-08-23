class TreeItem{
    float x;
    float y;
    float z;
    Boid boid;

    public TreeItem(Boid boid_){
        this.x = boid_.position.x;
        this.y = boid_.position.y;
        this.z = boid_.position.z;
        this.boid = boid_;
    }
}

class Cube{
    float x, y, z;
    float l;
    float xMin, xMax, yMin, yMax, zMin, zMax;
    
    public Cube(float x_, float y_, float z_, float l_){
        this.x = x_;
        this.y = y_;
        this.z = z_;
        this.l = l_;
        
        this.xMin = x - l;
        this.xMax = x + l;
        this.yMin = y - l;
        this.yMax = y + l;
        this.zMin = z - l;
        this.zMax = z + l;
    }
    
    Boolean contains(TreeItem treeItem) {
        return ( treeItem.x >= x - l && treeItem.x <= x + l &&
                 treeItem.y >= y - l && treeItem.y <= y + l &&
                 treeItem.z >= z - l && treeItem.z <= z + l    );
    }
    
    Boolean intersects(Cube range) {
    return !( range.x - range.l > x + l || range.x + range.l < x - l ||
              range.y - range.l > y + l || range.y + range.l < y - l ||
              range.z - range.l > z + l || range.z + range.l < z - l   );
    }
}

class OcTree {
    int octreeCapacity;
    boolean divided ;
    ArrayList <TreeItem> treeItems;
    
    Cube boundary;
    OcTree NWT, NET, SET, SWT;
    OcTree NWB, NEB, SEB, SWB;
    
    OcTree(Cube boundary, int octreeCapacity) {
      this.boundary = boundary; 
      this.octreeCapacity = octreeCapacity; 
      this.treeItems = new ArrayList <TreeItem>(); 
      this.divided = false; 
    }

  
    boolean insert(TreeItem treeItem) {
        if (!this.boundary.contains(treeItem)) {
          return false;
        }
    
        if (this.treeItems.size() < this.octreeCapacity) {
          this.treeItems.add(treeItem);
          return true;
        } else {
          if (!this.divided) {
            this.subdivide();
          }
          
        // N = North, S = South, E = East, W = West, B = Bottom, T = Top
        if (this.NWT.insert(treeItem)) {
          return true;
        } else if (this.NET.insert(treeItem)) {
          return true;
        } else if (this.SET.insert(treeItem)) {
          return true;
        } else if (this.SWT.insert(treeItem)) {
          return true;
        } else if (this.NWB.insert(treeItem)) {
          return true;
        } else if (this.NEB.insert(treeItem)) {
          return true;
        } else if (this.SEB.insert(treeItem)) {
          return true;
        } else if (this.SWB.insert(treeItem)) {
          return true;
        }
      }
        return false;
    }
  
    void subdivide() {
        float x = this.boundary.x;
        float y = this.boundary.y;
        float z = this.boundary.z;
        float l = this.boundary.l / 2;

    
        Cube NWTBoundary = new Cube(x - l, y - l, z - l, l);
        Cube NETBoundary = new Cube(x + l, y - l, z - l, l);
        Cube SETBoundary = new Cube(x + l, y + l, z - l, l);
        Cube SWTBoundary = new Cube(x - l, y + l, z - l, l);
        Cube NWBBoundary = new Cube(x - l, y - l, z + l, l);
        Cube NEBBoundary = new Cube(x + l, y - l, z + l, l);
        Cube SEBBoundary = new Cube(x + l, y + l, z + l, l);
        Cube SWBBoundary = new Cube(x - l, y + l, z + l, l);
        
        this.NWT = new OcTree(NWTBoundary, this.octreeCapacity);
        this.NET = new OcTree(NETBoundary, this.octreeCapacity);
        this.SET = new OcTree(SETBoundary, this.octreeCapacity);
        this.SWT = new OcTree(SWTBoundary, this.octreeCapacity);   
        this.NWB = new OcTree(NWBBoundary, this.octreeCapacity);
        this.NEB = new OcTree(NEBBoundary, this.octreeCapacity);
        this.SEB = new OcTree(SEBBoundary, this.octreeCapacity);
        this.SWB = new OcTree(SWBBoundary, this.octreeCapacity);
        this.divided = true; 
    }
  
    ArrayList<TreeItem> query(Cube range, ArrayList<TreeItem> found) {
      if (found == null) found = new ArrayList<TreeItem>(); 
  
      if (!this.boundary.intersects(range)) {
          return found; 
      } else {
          
          for (TreeItem treeItem : this.treeItems) {
            if (range.contains(treeItem)) {
              found.add(treeItem); 
            }
          }
      
        if (this.divided) {
            this.NWT.query(range, found);
            this.NET.query(range, found);
            this.SET.query(range, found);
            this.SWT.query(range, found);
            this.NWB.query(range, found);
            this.NEB.query(range, found);
            this.SEB.query(range, found);
            this.SWB.query(range, found);
        }
      }
      return found;
    }
    
    void show(color col, int strokeW){
        pushMatrix();
        strokeWeight(strokeW);
        stroke(col);
        noFill();
        translate(this.boundary.x, this.boundary.y, this.boundary.z);
        box(this.boundary.l * 2, this.boundary.l * 2, this.boundary.l * 2);
        popMatrix();
        
        if (this.divided){
            this.NWT.show(col, strokeW);
            this.NET.show(col, strokeW);
            this.SET.show(col, strokeW);
            this.SWT.show(col, strokeW);
            this.NWB.show(col, strokeW);
            this.NEB.show(col, strokeW);
            this.SEB.show(col, strokeW);
            this.SWB.show(col, strokeW);
        }
    }
}
