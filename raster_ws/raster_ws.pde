import frames.timing.*;
import frames.primitives.*;
import frames.processing.*;

// 1. Frames' objects
Scene scene;
Frame frame;
Vector v1, v2, v3;
// timing
TimingTask spinningTask;
boolean yDirection;
// scaling is a power of 2
int n = 4;
float step3 = 0.5;
float step = 1;
float step2 = 0.1;

// 2. Hints
boolean triangleHint = true;
boolean gridHint = true;
boolean antialliasing = false;
boolean b = false;
boolean debug = true;

// 3. Use FX2D, JAVA2D, P2D or P3D
String renderer = P3D;

void setup() {
  //use 2^n to change the dimensions
  size(800, 800, renderer);
  scene = new Scene(this);
  if (scene.is3D())
    scene.setType(Scene.Type.ORTHOGRAPHIC);
  scene.setRadius(width/2);
  scene.fitBallInterpolation();

  // not really needed here but create a spinning task
  // just to illustrate some frames.timing features. For
  // example, to see how 3D spinning from the horizon
  // (no bias from above nor from below) induces movement
  // on the frame instance (the one used to represent
  // onscreen pixels): upwards or backwards (or to the left
  // vs to the right)?
  // Press ' ' to play it :)
  // Press 'y' to change the spinning axes defined in the
  // world system.
  spinningTask = new TimingTask() {
    public void execute() {
      spin();
    }
  };
  scene.registerTask(spinningTask);

  frame = new Frame();
  frame.setScaling(width/pow(2, n));

  // init the triangle that's gonna be rasterized
  randomizeTriangle();
}

void draw() {
  background(0);
  stroke(0, 255, 0);
  if (gridHint)
    scene.drawGrid(scene.radius(), (int)pow( 2, n));
  if (triangleHint)
    drawTriangleHint();
  pushMatrix();
  pushStyle();
  scene.applyTransformation(frame);
  triangleRaster();
  popStyle();
  popMatrix();
}

// Implement this function to rasterize the triangle.
// Coordinates are given in the frame system which has a dimension of 2^n
void triangleRaster() {
  // frame.coordinatesOf converts from world to frame
  // here we convert v1 to illustrate the idea
  if (debug) {
    pushStyle();
    stroke(0, 255, 0);
    point(round(frame.coordinatesOf(v1).x()), round(frame.coordinatesOf(v1).y()));
    stroke(0, 0, 255);
    point(round(frame.coordinatesOf(v2).x()), round(frame.coordinatesOf(v2).y()));
    stroke(255, 0, 0);
    point(round(frame.coordinatesOf(v3).x()), round(frame.coordinatesOf(v3).y()));
    popStyle();
  }
  
  Vector pv1 = frame.coordinatesOf(v1);
  Vector pv2 = frame.coordinatesOf(v2);
  Vector pv3 = frame.coordinatesOf(v3);
  
  //if (matrixDet(pv1,pv2,pv3) <= 0){
  //  randomizeTriangle();
  //}else{
  int[] dims = dimentions();
  strokeWeight(0);
  float[] counter = {0,0};
  float[] colorAVG = {0,0,0}; 
  
  
  for(counter[0] = dims[2]; counter[0]<= dims[0]; counter[0]+=step){
     for(counter[1] = dims[3]; counter[1]<= dims[1]; counter[1]+=step){
     
     float brillo = percentage(pv1,pv2,pv3,counter);
       if(antialliasing){    
          if( brillo > 10 ){
           colorAVG = baricentric(pv1,pv2,pv3,counter);
           tint(255, 127);
           fill(color(round(255*colorAVG[0]), round(255*colorAVG[1]), round(255*colorAVG[2])),  500 * (brillo/100)   );
           rect(counter[0],counter[1], step, step);
          }
       }else{
           if( brillo > 40){
             colorAVG = baricentric(pv1,pv2,pv3,counter);
             tint(255, 127);
             fill(color(round(255*colorAVG[0]), round(255*colorAVG[1]), round(255*colorAVG[2]))   );
             rect(counter[0],counter[1], step, step);         
           }
       }  
       
       
       
     if (b == true){  
     float[] w = {0.0, 0.0, 0.0};
       w[0] = inTriangleA(pv2,pv3,counter);
       w[1] = inTriangleA(pv3,pv1,counter);
       w[2] = inTriangleA(pv1,pv2,counter);
       if(((w[0] > 0 )&& (w[1]> 0)  && (w[2] > 0))){
           colorAVG = baricentric(pv1,pv2,pv3,counter);
           fill(color(round(255*colorAVG[0]), round(255*colorAVG[1]), round(255*colorAVG[2])));
           rect(counter[0],counter[1], step, step);
       }
      }
     }
    }
   //}     
   
}

float percentage(Vector pv1,Vector pv2,Vector pv3,float[] counter){
  int total = 0;
  float[] counter2 = {0,0};
  for(counter2[0] = counter[0] ; counter2[0] < counter[0]+1; counter2[0]+=step2){
     for(counter2[1] = counter[1] ; counter2[1] < counter[1]+1; counter2[1]+=step2){
         stroke(255);
         float[] w = {0.0, 0.0, 0.0};
         w[0] = inTriangle(pv2,pv3,counter2);
         w[1] = inTriangle(pv3,pv1,counter2);
         w[2] = inTriangle(pv1,pv2,counter2);
         if(((w[0] > 0 )&& (w[1]> 0)  && (w[2] > 0)) ){
           total += 1;
         }
     }
  }
  float num = (1/step2);
  return (total * 100) /(num * num);
}


int[] dimentions(){
  
  int[] dim ={0,0,0,0}; 
  dim[0] = round(max(frame.coordinatesOf(v1).x(), frame.coordinatesOf(v2).x(), frame.coordinatesOf(v3).x())); //max X
  dim[1] = round(max(frame.coordinatesOf(v1).y(), frame.coordinatesOf(v2).y(), frame.coordinatesOf(v3).y())); // max Y
  dim[2] = round(min(frame.coordinatesOf(v1).x(), frame.coordinatesOf(v2).x(), frame.coordinatesOf(v3).x())); // min X
  dim[3] = round(min(frame.coordinatesOf(v1).y(), frame.coordinatesOf(v2).y(), frame.coordinatesOf(v3).y())); // min Y
  return dim;
}


int  matrixDet(Vector a, Vector b, Vector c){
   return round(((b.x() - a.x())*(c.y() - a.y())) - ((b.y() - a.y())*(c.x() - a.x())));
}

float inTriangleA(Vector a, Vector b, float[] c){ 
  return ((b.x()- a.x())*(c[1]+(step3/2) - a.y()) - (b.y()-a.y())*(c[0]+(step3/2)-a.x()));
}

float inTriangle(Vector a, Vector b, float[] c){ 
  return ((b.x()- a.x())*(c[1] - a.y()) - (b.y()-a.y())*(c[0]-a.x()));
}


float distance(Vector t1, Vector t2,float[] p){
  return ((t1.y()- t2.y())* p[0]) + ((t2.x()-t1.x())*p[1]) + (t1.x()+t2.y() - t2.x()*t1.y());
  //return ((round(posY1) - round(posY2))*posX) + ((round(posX2) - round(posX1))*posY) + (round(posX1)* round(posY2)) - (round(posX2)*round(posY1));
}

float[] baricentric(Vector pv1, Vector pv2, Vector pv3, float[] p){

  float[] results = {0.0,0.0, 0.0};
  float[] temp1 = {pv1.x(),pv1.y()};
  float[] temp2 = {pv2.x(),pv2.y()};
  float[] temp3 = {pv3.x(),pv3.y()};
  results[0] = distance(pv1, pv2, p) / distance(pv1,pv2, temp3);
  results[1] = distance(pv2, pv3, p) / distance(pv2,pv3, temp1);
  results[2] = distance(pv3, pv1, p) / distance(pv3,pv1, temp2);
  return results;
}





void randomizeTriangle() {
  int low = -width/2;
  int high = width/2;
  v1 = new Vector(random(low, high), random(low, high));
  v2 = new Vector(random(low, high), random(low, high));
  v3 = new Vector(random(low, high), random(low, high));
  Vector pv1 = frame.coordinatesOf(v1);
  Vector pv2 = frame.coordinatesOf(v2);
  Vector pv3 = frame.coordinatesOf(v3);
  
  if (matrixDet(pv1,pv2,pv3) <= 0){
    randomizeTriangle();
  }
}

void drawTriangleHint() {
  pushStyle();
  noFill();
  strokeWeight(2);
  stroke(255, 0, 0);
  triangle(v1.x(), v1.y(), v2.x(), v2.y(), v3.x(), v3.y());
  strokeWeight(5);
  stroke(0, 255, 255);
  point(v1.x(), v1.y());
  point(v2.x(), v2.y());
  point(v3.x(), v3.y());
  popStyle();
}

void spin() {
  if (scene.is2D())
    scene.eye().rotate(new Quaternion(new Vector(0, 0, 1), PI / 100), scene.anchor());
  else
    scene.eye().rotate(new Quaternion(yDirection ? new Vector(0, 1, 0) : new Vector(1, 0, 0), PI / 100), scene.anchor());
}

void keyPressed() {
  if (key == 'g')
    gridHint = !gridHint;
  if (key == 't')
    triangleHint = !triangleHint;
  if (key == 'd')
    debug = !debug;
  if (key == '+') {
    n = n < 7 ? n+1 : 2;
    frame.setScaling(width/pow( 2, n));
  }
  if (key == '-') {
    n = n >2 ? n-1 : 7;
    frame.setScaling(width/pow( 2, n));
  }
  if (key == 'r')
    randomizeTriangle();
  if (key == ' ')
    if (spinningTask.isActive())
      spinningTask.stop();
    else
      spinningTask.run(20);
  if (key == 'y')
    yDirection = !yDirection;
  if (key == 'a')
    antialliasing = !antialliasing;
  if (key == 'b')
    b = !b;  
  if (key == 's'){
    step -=  0.01;
    if (step < 0.01){
      step = 1;
    }
  }
}
