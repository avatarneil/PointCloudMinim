import org.openkinect.freenect.*;
import org.openkinect.processing.*;
import ddf.minim.*;

Minim minim;
AudioPlayer player;
int var;
float noiseScale=0.003;
Kinect kinect;
int s = 10;

// Angle for rotation
float a = 0;

// We'll use a lookup table so that we don't have to repeat the math over and over
float[] depthLookUp = new float[2048];

void setup() {
  // Rendering in P3D
  //Standard size for window is 800x600, I'm scaling it up to 2x that, so 1600x1200. But, for now I'm using fullScreen(P3D), we'll see how that works out.
  //size(1600, 1000, P3D);
  fullScreen(P3D);
  kinect = new Kinect(this);
  kinect.initDepth();
  minim = new Minim(this);
  player = minim.loadFile("audio.mp3");
  for (int i = 0; i < depthLookUp.length; i++) {
    depthLookUp[i] = rawDepthToMeters(i);
  }
}

void draw() {
  pushMatrix();
  background(0);
  int[] depth = kinect.getRawDepth();
  int skip = 3;
  translate(width/2, height/2, -50);
  rotateZ(a);
  for (int x = 0; x < kinect.width; x += skip) {
    for (int y = 0; y < kinect.height; y += skip) {
      int offset = x + y*kinect.width;
      int rawDepth = depth[offset];
      PVector v = depthToWorld(x, y, rawDepth);

      //setting noise parameters for gradient stroke
      float noiseVal = noise(x*noiseScale, y*noiseScale);
      float noiseVal2 = noise(x*noiseScale*2, y*noiseScale*2);
      float noiseVal3 = noise(x*noiseScale*3, y*noiseScale*3);
      stroke(noiseVal*255, noiseVal2*255, noiseVal3*255);
      
      //rawDepth stuff is to remove background
      if( rawDepth> 800){
        stroke(0,0,0);
      }
      
      //move and draw each dot
      pushMatrix();
      float factor = 200;
      float leftPlayer = player.left.get(0)*10;
      float leftPlayer2 = player.left.get(1)*10;
      float lerpLeftPlayer = lerp(leftPlayer, leftPlayer2, .5);
      float rightPlayer = player.right.get(0)*2;
      float rightPlayer2 = player.right.get(1)*2;
      float lerpRightPlayer = lerp(rightPlayer, rightPlayer2, .5);
      translate(s*(v.x*factor), s*(v.y*factor) + lerpLeftPlayer, s*(factor-v.z*factor));
      point(0, 0);
      popMatrix();
    }
  }
  popMatrix();
  
  //after closing previous matrices, draw the waveforms
  for (int i = 0; i < player.bufferSize() - 1; i++) {
    float x1 = map(i, 0, player.bufferSize(), 0, width );
    float x2 = map(i+1, 0, player.bufferSize(), 0, width );
    stroke(map(player.left.get(i), -1, 1, 0, 255), map(player.right.get(i), -1, 1, 0, 255), random(0, 255));
    //strokeWeight(2);
    line( x1, 50 + player.left.get(i)*50, x2, 50 + player.left.get(i+1)*50);
    line( x1, (height-50) + player.right.get(i)*50, x2, (height-50) + player.right.get(i+1)*50);
  }
  a += 0.01f; // Rotate
}
float rawDepthToMeters(int depthValue) {
  if (depthValue < 2047) {
    return (float)(1.0 / ((double)(depthValue) * -0.0030711016 + 3.3309495161));
  }
  return 0.0f;
}

//depthToWorld algorithms stolen from Stanford (ty <3)
PVector depthToWorld(int x, int y, int depthValue) {

  final double fx_d = 1.0 / 5.9421434211923247e+02;
  final double fy_d = 1.0 / 5.9104053696870778e+02;
  final double cx_d = 3.3930780975300314e+02;
  final double cy_d = 2.4273913761751615e+02;

  PVector result = new PVector();
  double depth =  depthLookUp[depthValue]; //rawDepthToMeters(depthValue);
  result.x = (float)((x - cx_d) * depth * fx_d);
  result.y = (float)((y - cy_d) * depth * fy_d);
  result.z = (float)(depth);
  return result;
}

//to play the audio
void keyPressed()
{
  if ( player.isPlaying() )
  {
    player.pause();
  } else if ( player.position() == player.length() )
  {
    player.rewind();
    player.play();
  } else
  {
    player.play();
  }
}