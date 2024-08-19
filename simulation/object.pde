class Object {
  PShape obj;
  color col;
  ArrayList<PVector> pointList;
  int scl;

  public Object(PShape obj_, color col_, int scl_) {
    this.obj = obj_;
    this.col = col_;
    this.scl = scl_;
  }

  void get_points(int childDiv, int vertexDiv) {
    ArrayList<PVector> list = new ArrayList<PVector>();
    for (int i=0; i < obj.getChildCount(); i++) {
      PShape child = obj.getChild(i);
      for (int j=0; j < child.getVertexCount(); j++) {
        if (i%childDiv == 0 && j==vertexDiv ) list.add(child.getVertex(j));
      }
    }
    this.pointList = list;
  }

  void show() {
    pushMatrix();
    translate(wall.x, wall.y, wall.z);
    scale(scl, scl, scl);
    //this.obj.setFill(this.col);
    shape(this.obj);
    popMatrix();
  }
}
