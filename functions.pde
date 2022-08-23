void gui() { 
  hint(DISABLE_DEPTH_TEST); 
  cam.beginHUD(); 
    cp5.draw(); 
  cam.endHUD(); 
  hint(ENABLE_DEPTH_TEST); 
}

void mousePressed(){
  if (mouseY < guiHeight) {
    cam.setActive(false);
  } else {
    cam.setActive(true);
  }
}

// MOVEMENT OF CAMERA

void cameraMove(int cameraWait, int cameraSmoothing){
    if(millis() - deadTime >= cameraWait ) {
        deadTime = millis();
        Rotation rot = new Rotation(RotationOrder.XYZ, random(TAU), random(TAU), random(TAU));
        Vector3D center = new Vector3D(width, height, depth); // look at the origin (0,0,0)
        double distance = random(800, 1000); // from this far away
        CameraState state = new CameraState(rot, center, distance);
        cam.setState(state, cameraSmoothing);
    }
}

// verb controls
void keyPressed() {
  
    if (key == 's' || key == 'S'){
      octreeShow = !octreeShow;
    }
    
    if (key == 'a' || key == 'A'){
      octreeCapacity += 1;
    }
    
    if (key == 'b' || key == 'B'){
      octreeCapacity -= 1;
    }
    
    if (key == 'r' || key == 'R'){
      recordVideo = !recordVideo;
    }
    
}

// dispaly walls of the system
void get_box(){
    noFill();
    strokeWeight(1);
    stroke(255);
    
    line(0, 0, wall.zMin, 0, wall.yMax, wall.zMin);
    line(0, 0, wall.zMax, 0, wall.yMax, wall.zMax);
    line(0, 0, wall.zMin, wall.xMax, 0, wall.zMin);
    line(0, 0, wall.zMax, wall.xMax, 0, wall.zMax);
    
    line(wall.xMax, 0, wall.zMin, wall.xMax, wall.yMax, wall.zMin);
    line(wall.xMax, 0, wall.zMax, wall.xMax, wall.yMax, wall.zMax);
    line(0, wall.yMax, wall.zMin, wall.xMax, wall.yMax, wall.zMin);
    line(0, wall.yMax, wall.zMax, wall.xMax, wall.yMax, wall.zMax);
    
    line(0, 0, wall.zMin,  0, 0, wall.zMax);
    line(0, wall.yMax, wall.zMin, 0, wall.yMax, wall.zMax);
    line(wall.xMax, 0, wall.zMin, wall.xMax, 0, wall.zMax);
    line(wall.xMax, wall.yMax, wall.zMin,  wall.xMax, wall.yMax, wall.zMax);
}



// Axis code
void calculateAxis( float length )
{
   // Store the screen positions for the X, Y, Z and origin
   axisXHud.set( screenX(length,0,0), screenY(length,0,0), 0 );
   axisYHud.set( screenX(0,length,0), screenY(0,length,0), 0 );     
   axisZHud.set( screenX(0,0,length), screenY(0,0,length), 0 );
   axisOrgHud.set( screenX(0,0,0), screenY(0,0,0), 0 );
}

void drawAxis( float weight )
{
   pushStyle();   // Store the current style information

     strokeWeight( weight );      // Line width

     stroke( 255,   0,   0 );     // X axis color (Red)
     line( axisOrgHud.x, axisOrgHud.y, axisXHud.x, axisXHud.y );
 
     stroke(   0, 255,   0 );
     line( axisOrgHud.x, axisOrgHud.y, axisYHud.x, axisYHud.y );

     stroke(   0,   0, 255 );
     line( axisOrgHud.x, axisOrgHud.y, axisZHud.x, axisZHud.y );


      fill(255);                   // Text color
      textFont( axisLabelFont );   // Set the text font

      text( "X", axisXHud.x, axisXHud.y );
      text( "Y", axisYHud.x, axisYHud.y );
      text( "Z", axisZHud.x, axisZHud.y );

   popStyle();    // Recall the previously stored style information
}
