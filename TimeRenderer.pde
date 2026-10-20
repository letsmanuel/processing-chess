RendererBaseLayout rendererBaseLayoutTimeRenderer = new RendererBaseLayout();

class TimeRenderer {

  String formatTime(int time) {
    int minutes = 0;
    int seconds = 0;

    for (int i = 0; i < time; i++) {
      seconds++;
      if (seconds > 59) {
        seconds = 0;
        minutes++;
      }
    }

    if (seconds < 10) {
      if (minutes < 10) {
        return "0"+minutes+":0"+seconds;
      } else {
        return minutes+":0"+seconds;
      }
    } else {
      if (minutes < 10) {
        return "0"+minutes+":"+seconds;
      } else {
        return minutes+":"+seconds;
      }
    }
  }

  float whiteActive = 1;
  float blackActive = 0;
  int lastTickMillis = -1;
  float switchDurationMs = 150;
  boolean timesInitialized = false;

  void tickTimes(int timeLeftWhite, int timeLeftBlack, boolean isWhiteTurn, GameStatus gameStatus) {
    String timeLeftWhiteText = formatTime(timeLeftWhite);
    String timeLeftBlackText = formatTime(timeLeftBlack);

    if (!timesInitialized) {
      whiteActive = isWhiteTurn ? 1 : 0;
      blackActive = isWhiteTurn ? 0 : 1;
      lastTickMillis = millis();
      timesInitialized = true;
    }

    int now = millis();
    float step = constrain((now - lastTickMillis) / switchDurationMs, 0, 1);
    lastTickMillis = now;

    whiteActive = moveToward(whiteActive, isWhiteTurn ? 1 : 0, step);
    blackActive = moveToward(blackActive, isWhiteTurn ? 0 : 1, step);

    int[] design = rendererBaseLayoutTimeRenderer.designs[gameStatus.playingFieldDesign][1];
    color inactiveColor = color(53, 53, 53);
    color activeColor = color(design[0], design[1], design[2]);

    drawTimeBox(410, 10, blackActive, inactiveColor, activeColor);
    drawTimeBox(410, 370, whiteActive, inactiveColor, activeColor);

    fill(255, 255, 255);
    text(timeLeftBlackText, 415, 12);
    text(timeLeftWhiteText, 415, 372);
  }

  void drawTimeBox(float x, float y, float amount, color inactiveColor, color activeColor) {
    float eased = amount * amount * (3 - 2 * amount);

    fill(lerpColor(inactiveColor, activeColor, eased));
    rect(x, y, 67, 25);

    if (eased > 0.01) {
      triangle(x, y, x, y + 25, x - 5 * eased, y + 12.5);
    }
  }

  float moveToward(float current, float target, float step) {
    if (current < target) return min(current + step, target);
    return max(current - step, target);
  }
}
