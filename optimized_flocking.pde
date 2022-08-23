// Flocking simulation
// v 2.0
// mcodeeee 2022-06-09
// flocking simulation with octree optimization and object avoidance

/***************************************
            TODO
 
 - pov camera of a boid
 - single octree class for boids and obstacles
 - take out boids from the avoid object
 - fix obstacle avoidance
 
 - topological distance 
 - improve wall avoidance with alignment component
 
****************************************/

import peasy.*;
import peasy.org.apache.commons.math.geometry.*;
import controlP5.*;

// OBSTACLE
Object shape;
int scl = 6;
PShape s;

// CAMERA
PeasyCam cam;
CameraState state;
long deadTime;
int cameraWait = 11000;
int cameraSmoothing = 10000;

// AXIS
PFont axisLabelFont;
PVector axisXHud, axisYHud, axisZHud, axisOrgHud;

// RECORDING
boolean recordData = false;
boolean recordVideo = false;
int SECONDS_TO_CAPTURE = 60;
int VIDEO_FRAME_RATE = 60;
int videoFramesCaptured = 0;

// GUI 
ControlP5 cp5;
float guiHeight = 50;
float noiseSlider;
float alignSlider;
float cohesionSlider;
float separationSlider;
boolean avoidWallsSlider = true;

// VERBS
boolean avoidWalls = true;

boolean octreeShow = false;
boolean twoSpecies = false;
boolean obstacleVerb = false;
boolean showPoints = false;
boolean showAxes = true;
boolean cameraVerb = false;

// PARAMETERS
int z_min = 0;
int depth;

float rMax = 120;
float cohesionRadius = 120, cohesionRadius2 = 120;
float alignmentRadius = 50, alignmentRadius2 = 50;
float separationRadius = 30, separationRadius2 = 30;
 
int interPerceptionRadius = 50;
int boyz_num = 1000;
int octreeCapacity = 10;
float alignMultiplier = .5;
float cohesionMultiplier = .25;
float separationMultiplier = .5;
float pitchMultiplier = 0.2;
float rollMultiplier = 0.5;
float noiseMultiplier = 0;
float wallMultiplier = 30;

float prevTime = 0;

// FLOCK INITIALIZATION
Cube wall;
OcTree octree1, octree2;
Flock flock1, flock2;

// OBSTACLE INITIALIZATION
ObstacleOcTree obstacleOcTree;
ObstacleCube obstacleWall;


// DATA EXPORT 
PrintWriter Flock1data;
PrintWriter Flock2data;
int dataCount = 0;

void setup() {  
  //frameRate(20);
  size(1000, 800, P3D);
  
  depth = height;
  smooth(8);
  
  // BOUND OF THE OCTREES
  float oof = 800;
  wall = new Cube(oof, oof, oof, oof);
  
  // CAMERA SETUP
  cam = new PeasyCam(this, 300);
  Rotation rot = new Rotation(RotationOrder.XYZ, PI, PI, 0);
  Vector3D center = new Vector3D(wall.x, wall.y, wall.z);
  CameraState state = new CameraState(rot, center, 1500);
  cam.setState(state, 1500);
  state = cam.getState();
  float fov      = PI/3;  // field of view
  float nearClip = 1;
  float farClip  = 100000;
  float aspect   = float(width)/float(height);  
  perspective(fov, aspect, nearClip, farClip);  
  
  // GUI
  cp5 = new ControlP5(this); 
  cp5.addSlider("noiseSlider").setPosition(120, 10).setSize(80, 30).setRange(0, 1).setValue(noiseMultiplier).setColorActive(#ffa700).setColorBackground(#757575).setColorForeground(#ffa700);
  cp5.addSlider("alignSlider").setPosition(300, 10).setSize(80, 30).setRange(0, 1).setValue(alignMultiplier).setColorActive(#ffa700).setColorBackground(#757575).setColorForeground(#ffa700); 
  cp5.addSlider("cohesionSlider").setPosition(500, 10).setSize(80, 30).setRange(0, 1).setValue(cohesionMultiplier).setColorActive(#ffa700).setColorBackground(#757575).setColorForeground(#ffa700); 
  cp5.addSlider("separationSlider").setPosition(700, 10).setSize(80, 30).setRange(0, 1).setValue(separationMultiplier).setColorActive(#ffa700).setColorBackground(#757575).setColorForeground(#ffa700); 
  cp5.addToggle("avoidWallsSlider").setPosition(900, 10).setSize(50,20);
  cp5.setAutoDraw(false);  
  
  // AXIS SETUP
  axisLabelFont = createFont( "Arial", 14);
  axisXHud      = new PVector();
  axisYHud      = new PVector();
  axisZHud      = new PVector();
  axisOrgHud    = new PVector();

  // FLOCK SETUP
  flock1 = new Flock(#FF030B, cohesionRadius, alignmentRadius, separationRadius);
  if (twoSpecies) flock2 = new Flock(#FEFF00, cohesionRadius2, alignmentRadius2, separationRadius2);
  
  // OBSTACLE SETUP
  if (obstacleVerb){
    s = loadShape("torus.obj");
    shape = new Object(s, color(255, 0, 0), scl);
    shape.get_points(5, 2);
    println("Number of points:", shape.pointList.size());
    obstacleWall = new ObstacleCube(wall.x, wall.y, wall.z, wall.l);
    obstacleOcTree = new ObstacleOcTree(obstacleWall, octreeCapacity);
    for (PVector item : shape.pointList) {
      obstacleOcTree.insert(new ObstacleTreeItem(item.x, item.y, item.z));
    }
  }
  
  // DATA SETUP
  Flock1data = createWriter("Flock1data" + str(dataCount) + ".txt"); 
  if (!twoSpecies)  Flock1data.println(str(boyz_num) +  "  " + str(noiseMultiplier) + "  " + str(alignMultiplier) + " " + str(cohesionMultiplier) + " " + str(separationMultiplier));
  if (twoSpecies) Flock1data.println(str(boyz_num) + "  " + str(interPerceptionRadius) + "  "  + str(noiseMultiplier) + "  " + str(alignMultiplier) + " " + str(cohesionMultiplier) + " " + str(separationMultiplier));
 
  Flock1data.println("n_c" + "  " + "n_a" + "  " + "x" + "  " + "y" + "  " + "z" + "  " + "vx" + "  " + "vy" + "  " + "vz" );
  
  if (twoSpecies){
    Flock2data = createWriter("Flock2data" + str(dataCount) + ".txt"); 
    Flock2data.println(str(boyz_num) + "  " + str(interPerceptionRadius) + "  " + str(noiseMultiplier) + "  " + str(alignMultiplier) + " " + str(cohesionMultiplier) + " " + str(separationMultiplier));
    Flock2data.println("n_c" + "  " + "n_a" + "  " + "x" + "  " + "y" + "  " + "z" + "  " + "vx" + "  " + "vy" + "  " + "vz" );
  }
  
}


void draw() { 
  background(27);
  lights();
  
  // IMPLEMENT OBSTACLE AVOIDANCE
  if (obstacleVerb) {
    shape.show();
    obstacleOcTree.show(255, 1);
  }
  
  // DISPLAY BOUND OF THE SYSTEM
  get_box();

  // RUN FLOCKS
  octree1 = new OcTree(wall, octreeCapacity);
  for (Boid b : flock1.boids) {
    octree1.insert(new TreeItem(b));
    if (recordData) {
      Flock1data.println(b.n_c + " " + b.n_a + " " + b.position.x + "  " + b.position.y + "  " + b.position.z + "  " + b.velocity.x + "  " + b.velocity.y + "  " + b.velocity.z ); 
    }
  }
  
  if (twoSpecies){
    octree2 = new OcTree(wall, octreeCapacity);
    for (Boid b : flock2.boids) {
      octree2.insert(new TreeItem(b));
      if (recordData) {
      Flock2data.println(b.n_c + " " + b.n_a + " " + b.position.x + "  " + b.position.y + "  " + b.position.z + "  " + b.velocity.x + "  " + b.velocity.y + "  " + b.velocity.z ); 
      }
    }
  }
  
  flock1.run(octree1, octree2);
  if (twoSpecies) flock2.run(octree2, octree1); 
  
  flock1.update();
  if (twoSpecies) flock2.update();
  
  //println(flock1.boids.get(0).cohesionRadius, flock1.boids.get(0).alignmentRadius);
  //println(flock1.boids.get(0).n_c, flock1.boids.get(0).n_a);
  
  if (!recordData){
    pushMatrix();
    strokeWeight(1);
    stroke(#FFFFFF);
    noFill();
    translate(flock1.boids.get(0).position.x, flock1.boids.get(0).position.y, flock1.boids.get(0).position.z);
    box(flock1.boids.get(0).r, flock1.boids.get(0).r, flock1.boids.get(0).r);
    popMatrix();
  }
  
  
  
  // RESET COLORS 
  for (Boid b : flock1.boids) {
    b.col = #FF030B;
  }
  
  // CAMERA MOVEMENT
  if (cameraVerb) cameraMove(cameraWait, cameraSmoothing);
  
  // GUI + ANALYSIS DISPLAY
  cam.beginHUD();
    fill(0);
    noStroke();
    rect(0,0,width, guiHeight);
    cp5.draw();
    String s = "Framerate " + str(int(frameRate)) ;
    String s2 = "Frames Captured " + str(videoFramesCaptured) + "/" + str(SECONDS_TO_CAPTURE*VIDEO_FRAME_RATE);
    fill(255);
    text(s, 10, 10, width, 400);
    text(s2, 10, 30, width, 400);
  cam.endHUD();
  
  
  // SHOW AXES
  if (showAxes){
   calculateAxis(500);
   cam.beginHUD();
   drawAxis(3);
   cam.endHUD();
  }
  
  
  // UPDATE PARAMETERS EVEN IF NOT RECORDING
  if (!recordData){
    if (avoidWalls != avoidWallsSlider || noiseMultiplier != noiseSlider || alignMultiplier != alignSlider || cohesionMultiplier != cohesionSlider || separationMultiplier != separationSlider){
      
      flock1 = new Flock(#E81C4F, cohesionRadius, alignmentRadius, separationRadius);
      if (twoSpecies) flock2 = new Flock(#FEFF00, cohesionRadius2, alignmentRadius2, separationRadius2);
      
      avoidWalls = avoidWallsSlider; 
      noiseMultiplier = noiseSlider;
      alignMultiplier = alignSlider;
      cohesionMultiplier = cohesionSlider;
      separationMultiplier = separationSlider;
      }
    }
  
  // UPDATE PARAMETERS, RESTART SIMULATION & SAVE DATA
  if (recordData) {
    if (videoFramesCaptured > VIDEO_FRAME_RATE * SECONDS_TO_CAPTURE) {
      Flock1data.flush(); // Writes the remaining data to the file
      Flock1data.close(); // Finishes the file
      
      if (twoSpecies){
        Flock2data.flush(); // Writes the remaining data to the file
        Flock2data.close(); // Finishes the file
      }
      dataCount++;
      
      avoidWalls = avoidWallsSlider; 
      noiseMultiplier = noiseSlider;
      alignMultiplier = alignSlider;
      cohesionMultiplier = cohesionSlider;
      separationMultiplier = separationSlider;
      
      // RESTART SIMULATION
      flock1 = new Flock(#E81C4F, cohesionRadius, alignmentRadius, separationRadius);
      if (twoSpecies) flock2 = new Flock(#FEFF00, cohesionRadius2, alignmentRadius2, separationRadius2);
      
      Flock1data = createWriter("Flock1data" + str(dataCount) + ".txt"); 
      if (!twoSpecies) Flock1data.println(str(boyz_num) + "  " + str(noiseMultiplier) + "  " + str(alignMultiplier) + " " + str(cohesionMultiplier) + " " +str(separationMultiplier) + " " );
      if (twoSpecies) Flock1data.println(str(boyz_num) + "  " + str(interPerceptionRadius) + "  "  + str(noiseMultiplier) + "  " + str(alignMultiplier) + " " + str(cohesionMultiplier) + " " + str(separationMultiplier));

      Flock1data.println("n_c" + "  " + "n_a" + "  " + "x" + "  " + "y" + "  " + "z" + "  " + "vx" + "  " + "vy" + "  " + "vz" );
      
      if (twoSpecies){
        Flock2data = createWriter("Flock2data" + str(dataCount) + ".txt"); 
        Flock2data.println(str(boyz_num) + "  " + str(interPerceptionRadius) + "  " + str(noiseMultiplier) + "  " + str(alignMultiplier) + " " + str(cohesionMultiplier) + " " +str(separationMultiplier) + " " );
        Flock2data.println("n_c" + "  " + "n_a" + "  " + "x" + "  " + "y" + "  " + "z" + "  " + "vx" + "  " + "vy" + "  " + "vz" );
      }
            
      videoFramesCaptured = 0;
      println("end of recording");
    } else {
      videoFramesCaptured++;
    }
  }
  
  // RECORDING VIDEO
  if (recordVideo) {
    saveFrame("export/####-export.tga");
    if (videoFramesCaptured > VIDEO_FRAME_RATE * SECONDS_TO_CAPTURE) {
      recordVideo = false;
      videoFramesCaptured = 0;
      println("end of recording");
    } else {
      videoFramesCaptured++;
    }
  }
}
