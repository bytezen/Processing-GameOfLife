class AppModel {
  private ArrayList<LemurButton> padButtons; 
  private ArrayListPattern pattern;
  private Bitmap bitmap,next;
  
  String playBtnAddr, clearBtnAddr;
  
  AppModel() {
    padButtons = new ArrayList<LemurButton>();
  }

  ArrayList<LemurButton> getPad() {
    return padButtons;
  }

  void initializePad(int padRows, int padCols, String padRootName) {
    int padCount = padRows * padCols;
    pattern = new ArrayListPattern(padRows,padCols);
    
    for (int i=0; i<padCount; ++i) {      
      LemurButton lb = new LemurButton(padRootName + i); 
      padButtons.add(lb);
      pattern.setValue(i,0);
    }
  }
  
  void parsePattern(ArrayList<Integer> values, int rows, int cols) {
    pattern = new ArrayListPattern(rows, cols);
    if( rows*cols <= values.size() ) {
      for(int i=0; i < values.size(); ++i ) {
        pattern.setValue(i,values.get(i));
      } 
    }
  }
  
  void setPixel(int ind, int value) {
    pattern.setValue(ind,value);
  }
  
  ArrayListPattern getPattern() { return pattern; }  
  
  public void setBitmap(Bitmap b) {
    bitmap = b;
  }
  
  public void setNextBitmap(Bitmap b) {
    next = b;
  }
  
  public Bitmap getBitmap() { return bitmap; }
  public Bitmap getNextBitmap() { return next; }
  
  public void setLemurPlayBtnAddr(String addrRoot) {
    playBtnAddr = "/"+addrRoot+"/x";
  }

  public String getLemurPlayBtnAddr() {
    return playBtnAddr;
  }
  
  public void setLemurClearBtnAddr(String addrRoot) {
    clearBtnAddr  = "/"+addrRoot+"/x";
  }  
  
  public String getLemurClearBtnAddr() {
    return clearBtnAddr;
  }  
}

