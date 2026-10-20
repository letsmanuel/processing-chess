interface FloatCallback  { void call(float v); }
interface BoolCallback   { void call(boolean v); }
interface IntCallback    { void call(int v); }
interface StringCallback { void call(String v); }
interface FloatFormatter { String format(float v); }

class UIComponents {

  boolean enabled = true;

  color textCol = color(255);
  color dimCol = color(170);
  color inactiveCol = color(53, 53, 53);
  color trackCol = color(53, 53, 53);

  float switchDurationMs = 150;
  int lastMillis = -1;
  float frameStep = 0;

  boolean outerClip = false;
  float outerClipY = 0;
  float outerClipH = 0;

  String activeId = null;
  String focusId = null;
  String focusBuffer = "";
  StringCallback focusCb = null;
  boolean focusNumeric = false;
  int focusMaxLen = 16;

  boolean pressedThisFrame = false;
  HashMap<String, Float> anim = new HashMap<String, Float>();

  color accent() {
    int[] d = rendererBaseLayout.designs[gameStatus.playingFieldDesign][1];
    return color(d[0], d[1], d[2]);
  }

  void click() {
    gameStatus.soundQueue = append(gameStatus.soundQueue, "click");
  }

  void pushOuterClip(float y, float h) {
    outerClip = true;
    outerClipY = y;
    outerClipH = h;
    clip(0, y, width, h);
  }

  void popOuterClip() {
    outerClip = false;
    noClip();
  }

  void applyClip(float cx, float cy, float cw, float ch) {
    if (!outerClip) {
      clip(cx, cy, cw, ch);
      return;
    }
    float top = max(cy, outerClipY);
    float bottom = min(cy + ch, outerClipY + outerClipH);
    clip(cx, top, cw, max(0, bottom - top));
  }

  void restoreClip() {
    if (outerClip) clip(0, outerClipY, width, outerClipH);
    else noClip();
  }

  float moveToward(float current, float target, float step) {
    if (current < target) return min(current + step, target);
    return max(current - step, target);
  }

  float hoverAmt(String key, boolean over) {
    Float prev = anim.get(key);
    float current = prev == null ? 0 : prev;
    current = moveToward(current, over ? 1 : 0, frameStep);
    anim.put(key, current);
    return current * current * (3 - 2 * current);
  }

  void onMousePressed() {
    if (!enabled) return;
    pressedThisFrame = true;
  }

  void onKeyPressed() {
    if (!enabled || focusId == null) return;

    if (key == ENTER || key == RETURN) {
      commitFocus();
    } else if (key == ESC) {
      key = 0;
      focusId = null;
    } else if (key == BACKSPACE) {
      if (focusBuffer.length() > 0) focusBuffer = focusBuffer.substring(0, focusBuffer.length() - 1);
    } else if (key != CODED && key >= 32 && key < 127 && focusBuffer.length() < focusMaxLen) {
      if (!focusNumeric || (key >= '0' && key <= '9')) focusBuffer += key;
    }
  }

  void endFrame() {
    int now = millis();
    if (lastMillis < 0) lastMillis = now;
    frameStep = constrain((now - lastMillis) / switchDurationMs, 0, 1);
    lastMillis = now;

    if (!enabled) focusId = null;
    if (pressedThisFrame && focusId != null) commitFocus();
    if (!mousePressed || !enabled) activeId = null;
    pressedThisFrame = false;
  }

  void blur() {
    if (focusId != null) commitFocus();
    activeId = null;
    pressedThisFrame = false;
  }

  void commitFocus() {
    String result = focusBuffer;
    StringCallback cb = focusCb;
    focusId = null;
    focusCb = null;
    if (cb != null) cb.call(result);
  }

  boolean take(boolean over) {
    if (!enabled || !pressedThisFrame || !over) return false;
    pressedThisFrame = false;
    click();
    return true;
  }

  boolean hit(float x, float y, float w, float h) {
    return mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
  }

  float animTo(String key, float target, float speed) {
    Float prev = anim.get(key);
    float a = (prev == null) ? target : prev;
    a = lerp(a, target, speed);
    if (abs(a - target) < 0.005) a = target;
    anim.put(key, a);
    return a;
  }

  void sideTriangles(float x, float y, float w, float h, float amount) {
    if (amount <= 0.01) return;
    triangle(x, y, x, y + h, x - 5 * amount, y + h / 2);
    triangle(x + w, y, x + w, y + h, x + w + 5 * amount, y + h / 2);
  }

  void label(String s, float x, float y) {
    pushStyle();
    fill(dimCol);
    textSize(14);
    textAlign(LEFT, CENTER);
    text(s, x, y);
    popStyle();
  }

  float slider(String id, String lbl, float x, float y, float w,
               float minV, float maxV, float step, float value, FloatCallback cb) {
    return slider(id, lbl, x, y, w, minV, maxV, step, value, null, cb);
  }

  float slider(String id, String lbl, float x, float y, float w,
               float minV, float maxV, float step, float value, FloatFormatter fmt, FloatCallback cb) {
    float trackY = y + 22;
    boolean over = enabled && hit(x - 8, trackY - 12, w + 16, 24);

    if (activeId == null && take(over)) activeId = id;

    if (enabled && id.equals(activeId) && mousePressed) {
      float t = constrain((mouseX - x) / w, 0, 1);
      float nv = minV + t * (maxV - minV);
      if (step > 0) nv = minV + round((nv - minV) / step) * step;
      nv = constrain(nv, minV, maxV);
      if (nv != value) {
        value = nv;
        if (cb != null) cb.call(nv);
      }
    }

    float t = (maxV == minV) ? 0 : (value - minV) / (maxV - minV);
    float hv = hoverAmt("h:" + id, over || id.equals(activeId));

    pushStyle();
    rectMode(CORNER);
    label(lbl, x, y + 6);
    fill(textCol);
    textSize(14);
    textAlign(RIGHT, CENTER);
    text(fmt != null ? fmt.format(value) : (step >= 1 ? str(round(value)) : nf(value, 0, 2)), x + w, y + 6);

    noStroke();
    fill(trackCol);
    rect(x, trackY - 2, w, 4);
    fill(accent());
    rect(x, trackY - 2, w * t, 4);
    fill(lerpColor(color(230), lerpColor(accent(), color(255), 0.35), hv));
    rect(x + w * t - 4, trackY - 10, 8, 20);
    popStyle();
    return value;
  }

  boolean toggle(String id, String lbl, float x, float y, boolean value, BoolCallback cb) {
    float tw = 40, th = 20;
    pushStyle();
    rectMode(CORNER);
    textSize(16);
    float totalW = tw + 12 + textWidth(lbl);
    boolean over = enabled && hit(x, y, totalW, th);

    if (take(over)) {
      value = !value;
      if (cb != null) cb.call(value);
    }

    float a = animTo(id, value ? 1 : 0, 0.3);
    float hv = hoverAmt("h:" + id, over);

    noStroke();
    fill(lerpColor(trackCol, accent(), a));
    rect(x, y, tw, th);
    sideTriangles(x, y, tw, th, hv);
    fill(255);
    rect(x + 3 + a * (tw - th), y + 3, th - 6, th - 6);

    fill(textCol);
    textAlign(LEFT, CENTER);
    text(lbl, x + tw + 12, y + th / 2 - 1);
    popStyle();
    return value;
  }

  String textField(String id, String lbl, float x, float y, float w, String value,
                   int maxLen, boolean numericOnly, StringCallback cb) {
    float fy = y + 14, fh = 26;
    boolean over = enabled && hit(x, fy, w, fh);
    boolean focused = id.equals(focusId);

    if (take(over)) {
      if (focusId != null && !focused) commitFocus();
      if (!focused) {
        focusId = id;
        focusBuffer = value;
        focusCb = cb;
        focusNumeric = numericOnly;
        focusMaxLen = maxLen;
        focused = true;
      }
    }

    String shown = focused ? focusBuffer : value;
    float hv = hoverAmt("h:" + id, over);

    pushStyle();
    rectMode(CORNER);
    label(lbl, x, y + 6);
    fill(lerpColor(inactiveCol, accent(), hv * 0.5));
    if (focused) {
      stroke(accent());
      strokeWeight(2);
    } else {
      noStroke();
    }
    rect(x, fy, w, fh);

    noStroke();
    fill(textCol);
    textSize(16);
    textAlign(LEFT, CENTER);
    text(shown, x + 8, fy + fh / 2 - 1);
    if (focused && (millis() / 500) % 2 == 0) {
      float cx = x + 9 + textWidth(shown);
      stroke(textCol);
      strokeWeight(1);
      line(cx, fy + 5, cx, fy + fh - 5);
    }
    popStyle();
    return shown;
  }

  int segmented(String id, String lbl, float x, float y, float w, String[] options,
                int selected, IntCallback cb) {
    float fy = y + 14, fh = 26;
    float segW = w / options.length;

    if (take(enabled && hit(x, fy, w, fh))) {
      int idx = constrain(floor((mouseX - x) / segW), 0, options.length - 1);
      if (idx != selected) {
        selected = idx;
        if (cb != null) cb.call(idx);
      }
    }

    pushStyle();
    rectMode(CORNER);
    label(lbl, x, y + 6);
    noStroke();
    textSize(16);
    textAlign(CENTER, CENTER);
    for (int i = 0; i < options.length; i++) {
      boolean over = enabled && hit(x + i * segW, fy, segW, fh);
      float hv = hoverAmt("h:" + id + i, over);
      fill(i == selected ? accent() : lerpColor(inactiveCol, accent(), hv * 0.7));
      rect(x + i * segW, fy, segW - 4, fh);
      fill(textCol);
      text(options[i], x + i * segW + (segW - 4) / 2, fy + fh / 2 - 1);
    }
    popStyle();
    return selected;
  }

  void button(String id, String lbl, float x, float y, float w, float h, boolean primary, Runnable cb) {
    button(id, lbl, x, y, w, h, primary, CENTER, cb);
  }

  void button(String id, String lbl, float x, float y, float w, float h, boolean primary, int alignH, Runnable cb) {
    boolean over = enabled && hit(x, y, w, h);
    if (take(over) && cb != null) cb.run();

    float hv = hoverAmt("h:" + id, over);
    color base = primary ? accent() : inactiveCol;
    color target = primary ? lerpColor(accent(), color(255), 0.2) : accent();

    pushStyle();
    rectMode(CORNER);
    noStroke();
    fill(lerpColor(base, target, hv));
    rect(x, y, w, h);
    sideTriangles(x, y, w, h, hv);
    fill(textCol);
    textSize(15);
    textAlign(alignH, CENTER);
    text(lbl, alignH == LEFT ? x + 14 : x + w / 2, y + h / 2);
    popStyle();
  }

  void arrowButton(float x, float y, float w, float h, boolean left, boolean over, boolean active) {
    noStroke();
    fill(over && active ? accent() : inactiveCol);
    rect(x, y, w, h);
    fill(active ? textCol : color(90));
    float cx = x + w / 2;
    float cy = y + h / 2;
    if (left) triangle(cx + 4, cy - 6, cx + 4, cy + 6, cx - 5, cy);
    else triangle(cx - 4, cy - 6, cx - 4, cy + 6, cx + 5, cy);
  }

  int designPicker(String id, String lbl, float x, float y, float w,
                   int[][][] designs, int selected, IntCallback cb) {
    float tile = 30, gap = 8, arrowW = 26;
    float fy = y + 14;
    float viewX = x + arrowW + 8;
    float viewW = w - 2 * (arrowW + 8);
    float stride = tile + gap;
    int count = designs.length;
    int visible = floor((viewW + gap) / stride);
    float maxScroll = max(0, count - visible);

    if (anim.get(id + "T") == null) {
      float start = constrain(selected - visible / 2.0, 0, maxScroll);
      anim.put(id + "T", start);
      anim.put(id + "S", start);
      anim.put(id + "P", (float) selected);
    }

    float target = anim.get(id + "T");

    boolean overL = enabled && hit(x, fy, arrowW, tile);
    boolean overR = enabled && hit(x + w - arrowW, fy, arrowW, tile);
    if (take(overL)) target = constrain(round(target) - 1, 0, maxScroll);
    if (take(overR)) target = constrain(round(target) + 1, 0, maxScroll);
    anim.put(id + "T", target);

    float scroll = animTo(id + "S", target, 0.2);
    float selPos = animTo(id + "P", selected, 0.25);

    boolean inView = enabled && hit(viewX, fy, viewW, tile);
    for (int i = 0; i < count; i++) {
      float tx = viewX + (i - scroll) * stride;
      if (take(inView && hit(tx, fy, tile, tile))) {
        if (i != selected) {
          selected = i;
          if (cb != null) cb.call(i);
        }
      }
    }

    pushStyle();
    rectMode(CORNER);
    noStroke();
    label(lbl, x, y + 6);

    arrowButton(x, fy, arrowW, tile, true, overL, target > 0);
    arrowButton(x + w - arrowW, fy, arrowW, tile, false, overR, target < maxScroll);

    applyClip(viewX - 2, fy - 2, viewW + 4, tile + 4);
    float half = tile / 2;
    for (int i = 0; i < count; i++) {
      float tx = viewX + (i - scroll) * stride;
      if (tx + tile < viewX - 2 || tx > viewX + viewW + 2) continue;
      color light = color(designs[i][0][0], designs[i][0][1], designs[i][0][2]);
      color dark = color(designs[i][1][0], designs[i][1][1], designs[i][1][2]);
      noStroke();
      fill(light);
      rect(tx, fy, half, half);
      rect(tx + half, fy + half, half, half);
      fill(dark);
      rect(tx + half, fy, half, half);
      rect(tx, fy + half, half, half);
      if (inView && hit(tx, fy, tile, tile)) {
        noFill();
        stroke(255, 110);
        strokeWeight(1);
        rect(tx, fy, tile, tile);
      }
    }
    noFill();
    stroke(255);
    strokeWeight(2);
    rect(viewX + (selPos - scroll) * stride, fy, tile, tile);
    restoreClip();
    popStyle();
    return selected;
  }
}
