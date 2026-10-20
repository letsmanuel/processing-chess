
import java.util.ArrayList;

class ButtonRenderer {

  ArrayList<Button> buttons = new ArrayList<Button>();

  class Button {
    String label;
    int textSize;
    int x, y, w, h;
    Runnable action;

    Button(String label, int textSize, int x, int y, int w, int h, Runnable action) {
      this.label = label;
      this.textSize = textSize;
      this.x = x;
      this.y = y;
      this.w = w;
      this.h = h;
      this.action = action;
    }

    void drawButton() {
      boolean hovered = mouseX >= x && mouseX <= x + w &&
                        mouseY >= y && mouseY <= y + h;

      rectMode(CORNER);
      stroke(hovered ? color(130, 190, 255) : color(75, 85, 105));
      strokeWeight(2);
      fill(hovered ? color(65, 100, 150) : color(43, 50, 67));
      rect(x, y, w, h, 5);

      fill(255);
      textSize(this.textSize);
      textAlign(CENTER, CENTER);
      text(label, x + w / 2, y + h / 2);
    }
  }

  void createNewButton(String label, int textSize, int x, int y, int w, int h, Runnable action) {
    buttons.add(new Button(label, textSize, x, y, w, h, action));
  }

  void tickAllButtons() {
    for (Button button : buttons) {
      button.drawButton();
    }
  }

  void handleMousePressed() {
    for (int i = buttons.size() - 1; i >= 0; i--) {
      Button button = buttons.get(i);

      if (mouseX >= button.x && mouseX <= button.x + button.w &&
          mouseY >= button.y && mouseY <= button.y + button.h) {
        if (button.action != null) {
          button.action.run();
        }
        return;
      }
    }
  }

  void removeButton(String label) {
    for (int i = buttons.size() - 1; i >= 0; i--) {
      if (buttons.get(i).label.equals(label)) {
        buttons.remove(i);
      }
    }
  }

  void removeAllButtons() {
    buttons.clear();
  }
}
