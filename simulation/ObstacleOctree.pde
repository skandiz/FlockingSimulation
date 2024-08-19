class ObstacleTreeItem{
  float x;
  float y;
  float z;
  public ObstacleTreeItem(float x_, float y_, float z_){
      this.x = width + scl*x_;
      this.y = height + scl*y_;
      this.z = depth + scl*z_;
  }
}

class ObstacleCube{
  float x, y, z;
  float l;
  float xMin, xMax, yMin, yMax, zMin, zMax;
  
  public ObstacleCube(float x_, float y_, float z_, float l_){
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
  
  Boolean obstacleContains(ObstacleTreeItem obstacleTreeItem) {
    return ( obstacleTreeItem.x >= x - l && obstacleTreeItem.x <= x + l &&
             obstacleTreeItem.y >= y - l && obstacleTreeItem.y <= y + l &&
             obstacleTreeItem.z >= z - l && obstacleTreeItem.z <= z + l   );
  }
  
  Boolean obstacleIntersects(ObstacleCube range) {
    return !( range.x - range.l > x + l || range.x + range.l < x - l ||
              range.y - range.l > y + l || range.y + range.l < y - l ||
              range.z - range.l > z + l || range.z + range.l < z - l   );
    }
}

class ObstacleOcTree{
  int octreeCapacity;
  boolean divided ;
  ArrayList <ObstacleTreeItem> obstacleTreeItems;
  
  ObstacleCube boundary;
  ObstacleOcTree NWT, NET, SET, SWT;
  ObstacleOcTree NWB, NEB, SEB, SWB;
  
  ObstacleOcTree(ObstacleCube boundary, int octreeCapacity) {
    this.boundary = boundary; 
    this.octreeCapacity = octreeCapacity; 
    this.obstacleTreeItems = new ArrayList <ObstacleTreeItem>(); 
    this.divided = false; 
  }

  boolean insert(ObstacleTreeItem obstacleTreeItem) {
    if (!this.boundary.obstacleContains(obstacleTreeItem)) {
      return false;
    }

    if (this.obstacleTreeItems.size() < this.octreeCapacity) {
      this.obstacleTreeItems.add(obstacleTreeItem);
      return true;
    } else {
        if (!this.divided) {
          this.subdivide();
        }
        
        // N = North, S = South, E = East, W = West, B = Bottom, T = Top
        if (this.NWT.insert(obstacleTreeItem)) {
          return true;
        } else if (this.NET.insert(obstacleTreeItem)) {
          return true;
        } else if (this.SET.insert(obstacleTreeItem)) {
          return true;
        } else if (this.SWT.insert(obstacleTreeItem)) {
          return true;
        } else if (this.NWB.insert(obstacleTreeItem)) {
          return true;
        } else if (this.NEB.insert(obstacleTreeItem)) {
          return true;
        } else if (this.SEB.insert(obstacleTreeItem)) {
          return true;
        } else if (this.SWB.insert(obstacleTreeItem)) {
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

    ObstacleCube NWTBoundary = new ObstacleCube(x - l, y - l, z - l, l);
    ObstacleCube NETBoundary = new ObstacleCube(x + l, y - l, z - l, l);
    ObstacleCube SETBoundary = new ObstacleCube(x + l, y + l, z - l, l);
    ObstacleCube SWTBoundary = new ObstacleCube(x - l, y + l, z - l, l);
    ObstacleCube NWBBoundary = new ObstacleCube(x - l, y - l, z + l, l);
    ObstacleCube NEBBoundary = new ObstacleCube(x + l, y - l, z + l, l);
    ObstacleCube SEBBoundary = new ObstacleCube(x + l, y + l, z + l, l);
    ObstacleCube SWBBoundary = new ObstacleCube(x - l, y + l, z + l, l);
    
    this.NWT = new ObstacleOcTree(NWTBoundary, this.octreeCapacity);
    this.NET = new ObstacleOcTree(NETBoundary, this.octreeCapacity);
    this.SET = new ObstacleOcTree(SETBoundary, this.octreeCapacity);
    this.SWT = new ObstacleOcTree(SWTBoundary, this.octreeCapacity);   
    this.NWB = new ObstacleOcTree(NWBBoundary, this.octreeCapacity);
    this.NEB = new ObstacleOcTree(NEBBoundary, this.octreeCapacity);
    this.SEB = new ObstacleOcTree(SEBBoundary, this.octreeCapacity);
    this.SWB = new ObstacleOcTree(SWBBoundary, this.octreeCapacity);
    this.divided = true; 
  }

  ArrayList<ObstacleTreeItem> query(ObstacleCube range, ArrayList<ObstacleTreeItem> found) {
    if (found == null) found = new ArrayList<ObstacleTreeItem>(); 

    if (!this.boundary.obstacleIntersects(range)) {
        return found; 
    } else {
        for (ObstacleTreeItem obstacleTreeItem : this.obstacleTreeItems) {
          if (range.obstacleContains(obstacleTreeItem)) {
            found.add(obstacleTreeItem); 
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
    if (showPoints){
      for (int i=0; i < obstacleTreeItems.size(); i++) {
        ObstacleTreeItem p = obstacleTreeItems.get(i);
        stroke(255);
        strokeWeight(10);
        point(p.x-wall.x, p.y-wall.y, p.z-wall.z);
      }
    }
  }
}
