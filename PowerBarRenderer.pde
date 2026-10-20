class PowerBarRenderer {
  
  float smoothBarValue = 0.5;
   
  float getSharedBar(int whiteScore){
   if (whiteScore >= 99000) return 1.0;
   if (whiteScore <= -99000) return 0.0;
   return 1.0 / (1.0  + exp(-0.00368208 * whiteScore));
  }
  
  void drawPowerBar(int power){
    float target = getSharedBar(power);
    smoothBarValue = lerp(smoothBarValue, target, .15);
    
    noStroke();
    fill(40);
    rect(410, 50, 20, 300);
    
    float whiteH = 300 * smoothBarValue;
    fill(240);
    rect(410, 350 - whiteH, 20, whiteH);
    
    stroke(128);
    line(410,200,430,200);
  }
  
}
