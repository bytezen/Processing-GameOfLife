import toxi.util.*;
import java.awt.FileDialog;
import java.io.File;
import java.util.Map;
import java.util.HashMap;

import java.util.regex.*;
import oscP5.*;
import netP5.*;

// -=-=-=-=--=-==-=-=-=-=-=-=
// -=-=- OUTPUT DATA -=-=--=-
// -=-=-=-=--=-==-=-=-=-=-=-=
boolean SAVE_OUTPUT = false;
boolean OSC_CONNECT  = true;

// -=-=-=-=--=-==-=-=-

String outputFile;
int outFileCounter = 0;

boolean DEBUG = false;



// -=-=-=CONFIG VARS with DEFAULTS
int rows = 30, cols = 15;   //Default - Override in config file
int gWidth = 100, gHeight = 100; //Default - Override in config file
int renderSpeed = 5;


Bitmap bitmap, next;
RLEParser parser = new RLEParser();

boolean paused = false;

// -=-=-=-=--=-==-=-=-
OscP5 osc;
int listenPort = 8000;

// -=-=-=-=--=-==-=-=-
LemurController lemurController;
ConfigInterface lemurConfig;


// -=-=-=-=--=-==-=-=-
String configurationFile = "data/config.xml";
Config config;


// -=-=-=-=--=-==-=-=--=-=-=-=--=-==-=-=--=-=-=-=--=-==-=-=-

// -=-=-=-=--=-==-=-=-
//  CODE
// -=-=-=-=--=-==-=-=-


void initialize() {
  config = new Config(configurationFile);
  lemurConfig = config.getLemurConfig();
  lemurController = new LemurController(16*9);

  try {
    String[] matrixSize = config.getValue(config.APP_GMATRIXSIZE).split(",");
    rows = Integer.parseInt(matrixSize[0]);  
    cols = Integer.parseInt(matrixSize[1]);

    String[] configSize = config.getValue(config.APP_GSIZE).split(",");
    gWidth = Integer.parseInt(configSize[0]);
    gHeight = Integer.parseInt(configSize[1]);

    renderSpeed = Integer.parseInt(config.getValue( config.APP_RENDERSPEED));

    //BITMAP configuration
    drawAsRectangle = config.getValue(config.CELL_SHAPE).equals(config.RECTANGLE_CELL); 

    //LEMUR configuration
    //    lemurIPInAddr = lemurConfig.getValue(config.LEMUR_IPADDR);
    //    lemurSendPort = Integer.parseInt(lemurConfig.getValue(config.LEMUR_IN_PORT));

    String[] lemurPadSize = lemurConfig.getValue(config.LEMUR_PADSIZE).split(","); 
    int lemurRows = Integer.parseInt(lemurPadSize[0]);
    int lemurCols = Integer.parseInt(lemurPadSize[1]);   
    String padRootName = lemurConfig.getValue(config.LEMUR_PAD_BTN_NAME);

    lemurController.addSwitchPadController(padRootName, lemurRows*lemurCols);
  } 
  catch (Exception e) {
    println(e);
    println(e.getStackTrace());
  }
}


void setup() {
  size(1024, 768, P2D);
  frameRate(30);
  rectMode(CENTER);

  initialize();

  if (OSC_CONNECT) {
    osc = new OscP5(this, listenPort);
  }

  bitmap = new Bitmap(width/2 - gWidth/2, height/2 - gHeight/2, gWidth, gHeight, rows, cols);
  next = new Bitmap(width/2 - gWidth/2, height/2 - gHeight/2, gWidth, gHeight, rows, cols);

//  loadFile();
}


void draw() {
  background(0);

  bitmap.update();
  bitmap.draw();

  if (frameCount % renderSpeed == 0 && !paused ) {
    calculateLifeValue(bitmap);
    bitmap.setPixels(next.getPixels());
  }
}


void randomBitmap() {
  for (int i=0; i < bitmap.getPixelCount(); ++i ) {
    if (random(1.0) < 0.5 ) {
      bitmap.getPixel(i).setValue(1);
    } 
    else {
      bitmap.getPixel(i).setValue(0);
    }
  }
}


void mousePressed() {
  randomBitmap();
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    println("saving frame = " + frame );
    saveFrame("screengrabs/grab#####.png");
  }
  if (key == 'e' || key == 'E') {
    println("exporting bitmap to " + outputFile);
    bitmap.save(outputFile);
  }
  else if ( key == 'o' || key =='O') {
    loadFile();
  }
  else if ( key  == 'p' || key =='P') {
    paused = !paused;
  }
}



// -=-=-=-=-= Life ==-
// Rule B3/S23

void calculateLifeValue( Bitmap b ) {
  next.clear();
  int cols = b.getCols(); 

  //kernel array
  int[] kernel = {
    -(cols + 1), -cols, -(cols-1), 
    -1, 1, 
    (cols - 1), cols, (cols+1)
    };

    //convolution array
    int[] conv = new int[8];

  for ( int i=1; i < b.getRows()-1; ++i ) {
    for ( int j=1; j < cols-1; ++j ) {

      int neighborhood = 0;
      int index = i * b.getCols() + j;
      if (DEBUG)
        print("::"+i);

      for ( int k = 0; k < conv.length; ++k) {
        conv[k] = b.getPixel( kernel[k] + index ).getValue();
        neighborhood |= conv[k] << (conv.length - 1 - k);
      }    
      int score = scorePixel(neighborhood, b.getPixel(i, j));
      next.setPixel(i, j, score);

      if (DEBUG)
        print("    " + Integer.toBinaryString(neighborhood));
    }
  }
}


//Hamming Weight implementation - from stackoverflow -- 
//http://stackoverflow.com/questions/8871204/count-number-of-1s-in-binary-representation

int scorePixel(int neighborhood, BitmapCell bmp) {
  int score = -1;
  int count = 0;
  while ( neighborhood > 0 ) {
    count = count + 1;
    neighborhood = neighborhood & ( neighborhood - 1);
  }

  if ( bmp.getValue() == 1 ) { //alive
    if (count <= 1 || count > 3 ) { //death
      score = 0;
    } 
    else {
      score = 1;
    }
  } 
  else {
    if (count == 3) {
      score = 1;
    } 
    else {
      score  = 0;
    }
  } 
  return score;
}

void loadFile() {
  String path = FileUtils.showFileDialog(
  frame, 
  "An RLE file to load...", 
  dataPath("") +"/rle", 
  new String[] { 
    ".rle", ".txt"
  }
  , 
  FileDialog.LOAD
    );   

  //String path = dataPath("") +"/rle/glider.rle";

  if (path != null) {
    RLEPattern pattern;
    pattern = parser.parse(path);
    Bitmap p = new Bitmap(pattern, gWidth, gHeight, rows, cols, rows/2 - pattern.rows/2, cols/2 - pattern.cols/2);
    bitmap.setPixels(p.getPixels());
    bitmap.draw();
  }
}


//--=-=-=-=-=-=-=-=-=-=
//  OSC
//--=-=-=-=-=-=-=-=-=-=
void oscEvent(OscMessage msg) {
  //  println("### received an osc message with addrpattern "+msg.addrPattern()+" and typetag "+msg.typetag());  
  //println("Lemur controller can handle message: " + lemurController.canHandleMessage(msg));


  msg.print();
  println("can handle message - " + lemurController.canHandleMessage(msg)); 
  lemurController.handleMessage(msg); 
}


// -=-=-=-=--=-==-=-=-
//  Interfaces
// -=-=-=-=--=-==-=-=-
interface ConfigInterface {
  public String getValue(String configKey) throws Exception;
}

interface InterfaceLemurController {
  boolean canHandleMessage(OscMessage msg);
  public void handleMessage(OscMessage msg);
}


// -=-=-=-=--=-==-=-=-
//  Static variables
// -=-=-=-=--=-==-=-=-
static boolean drawAsRectangle = true;

