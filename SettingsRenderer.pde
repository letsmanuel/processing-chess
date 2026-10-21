class SettingsRenderer {

  final int PAGE_HOME = 0;
  final int PAGE_GAME = 1;
  final int PAGE_LOOK = 2;
  final int PAGE_ADVANCED = 3;
  final int PAGE_CREDITS = 4;

  int page = 0;
  String[] pageTitles = {"Einstellungen", "Spiel", "Darstellung", "Erweitert", "Credits"};

  float scroll = 0;
  float targetScroll = 0;
  float contentHeight = 0;
  float scrollEase = 0.2;
  float wheelStep = 40;
  float scrollSensitivity = 1.0;

  float headerH = 64;
  float footerH = 64;
  float colMax = 920;
  float sideMargin = 60;
  float designPickerH = 120;
  float cy = 0;

  float panelAlpha = 215;

  float angle = 0;
  float targetAngle = 0;
  float rotateSpeed = 0.12;

  float iconX = 550;
  float iconY = 350;

  boolean wasHovering = false;
  boolean settingsOpen = false;
  float hoverAmount = 0;
  float hoverSpeed = 0.15;

  float baseSize = 50;
  float hoverSize = 60;

  color baseColor = color(224);
  color hoverColor = color(120, 190, 255);

  PShape playerIcon;
  PShape botIcon;

  UIComponents ui = new UIComponents();

  int pendingEngineMode = 2;
  int pendingElo = 3200;
  boolean pendingWhiteBot = false;
  boolean pendingBlackBot = true;
  int pendingTimeLimit = 600;
  int pendingThinkTime = 500;

  String[] engineNames = {"Experimentell", "Smart", "Auto"};
  String numberTrick = ""+gameStatus.engineVersion;
  String[][] creditsProject = {
    {"Entwicklung", "PAUL STIA."},
    {"Version", numberTrick}
  };

  String[][] creditsEngines = {
    {"Experimentell", "PROC.ENGINE 1.5"},
    {"Smart", "Stockfish 19 (GPL v3)"}
  };

  String[][] creditsTech = {
    {"Framework", "Processing"},
    {"Sound Package", "Sound by Processing Team"},
    {"Stockfish", "Stockfish Team"}
  };

  String[][] creditsThanks = {
    {"McCarthy", "MinMax Alpha-Beta Pruning"},
    {"Sebastian Lague", "CODE ADVENTURE: Chess"},
    {"Chess.com Team", "Sounds"},
    {"und DU","Fürs benutzen der App"}
  };

  String[] creditsAi = {
    "Generative KI wurde ausschlieslich für das Testen von Konzepten, sowie der Theorie hinter Chess Engines verwendet. Protoypen für UI wurden ebenfalls generiert, allerdings durch per Hand geschriebene ersetzt. Systeme wie Code Rabbit wurden eingesetzt für die Fehlersuche!"
  };

  void init() {
    playerIcon = loadShape("images/device-player.svg");
    botIcon = loadShape("images/device-bot.svg");
  }

  void rotateBy(float radiansToAdd) {
    targetAngle += radiansToAdd;
  }

  void rotateTo(float newTarget) {
    targetAngle = newTarget;
  }

  boolean isHovering() {
    return iconHit() && !mousePressed;
  }

  boolean iconHit() {
    return mouseX > iconX && mouseX < iconX + baseSize - 5 && mouseY > iconY && mouseY < iconY + baseSize - 5;
  }

  boolean interactive() {
    return settingsOpen && !overlayRenderer.pauseGameDueToAnimation;
  }

  void onMousePressed() {
    if (!interactive()) return;
    ui.onMousePressed();
  }

  void onKeyPressed() {
    if (!interactive()) return;
    ui.onKeyPressed();
  }

  void onMouseWheel(float count) {
    if (!interactive()) return;
    targetScroll = constrain(targetScroll + count * wheelStep * scrollSensitivity, 0, maxScroll());
  }

  void toggleSettings() {
    if (overlayRenderer.pauseGameDueToAnimation) return;
    if (settingsOpen) closeSettings();
    else openSettings();
  }

  void loadPending() {
    pendingEngineMode = gameStatus.engineMode;
    pendingElo = gameStatus.stockfishElo;
    pendingWhiteBot = gameStatus.enginePlayAsWhite;
    pendingBlackBot = gameStatus.enginePlayAsBlack;
    pendingTimeLimit = gameStatus.timeLimit;
    pendingThinkTime = gameStatus.stockfishMaxThinkingTime;
  }

  void resetPendingToDefaults() {
    pendingEngineMode = 2;
    pendingElo = 3200;
    pendingWhiteBot = false;
    pendingBlackBot = true;
    pendingTimeLimit = 600;
    pendingThinkTime = 500;
  }

  void openSettings() {
    loadPending();
    goTo(PAGE_HOME);
    settingsOpen = true;
  }

  void closeSettings() {
    ui.blur();
    settingsOpen = false;
  }

  void goTo(int newPage) {
    ui.blur();
    page = newPage;
    scroll = 0;
    targetScroll = 0;
  }

  float colW() {
    return min(width - 2 * sideMargin, colMax);
  }

  float colX() {
    return (width - colW()) / 2;
  }

  float viewTop() {
    return headerH;
  }

  float viewBottom() {
    return height - footerH;
  }

  float viewHeight() {
    return viewBottom() - viewTop();
  }

  float maxScroll() {
    return max(0, contentHeight - viewHeight());
  }

  boolean mouseInView() {
    return mouseY > viewTop() && mouseY < viewBottom();
  }

  void tickSettings() {
    ui.enabled = interactive();

    boolean hovering = isHovering();
    if (hovering && !wasHovering && abs(targetAngle - angle) < 0.05) {
      rotateBy(PI);
    }
    wasHovering = hovering;

    float hoverTarget = hovering ? 1 : 0;
    hoverAmount = lerp(hoverAmount, hoverTarget, hoverSpeed);
    if (abs(hoverTarget - hoverAmount) < 0.005) hoverAmount = hoverTarget;

    angle = lerp(angle, targetAngle, rotateSpeed);
    if (abs(targetAngle - angle) < 0.001) angle = targetAngle;

    float currentSize = lerp(baseSize, hoverSize, hoverAmount);
    float centerX = iconX + baseSize / 2;
    float centerY = iconY + baseSize / 2;

    drawSettingsIcon(
      centerX - currentSize / 2,
      centerY - currentSize / 2,
      currentSize
      );

    if (settingsOpen) drawSettingsFrame();
    ui.endFrame();
  }

  void drawSettingsIcon(float x, float y, float size) {
    float s = size / 32.0;

    pushStyle();
    pushMatrix();

    translate(x + size / 2, y + size / 2);
    rotate(angle);
    scale(s);

    noFill();
    stroke(lerpColor(baseColor, hoverColor, hoverAmount));
    strokeWeight(2);
    strokeJoin(ROUND);
    strokeCap(ROUND);

    int teeth = 6;
    float outerR = 12;
    float rootR = 9;
    float step = TWO_PI / teeth;

    beginShape();
    for (int i = 0; i < teeth; i++) {
      float a = radians(90) + i * step;

      vertex(cos(a - radians(20)) * rootR, sin(a - radians(20)) * rootR);
      vertex(cos(a - radians(12)) * outerR, sin(a - radians(12)) * outerR);
      vertex(cos(a + radians(12)) * outerR, sin(a + radians(12)) * outerR);
      vertex(cos(a + radians(20)) * rootR, sin(a + radians(20)) * rootR);
      vertex(cos(a + radians(30)) * rootR, sin(a + radians(30)) * rootR);
    }
    endShape(CLOSE);
    ellipseMode(CENTER);
    ellipse(0, 0, 8, 8);

    popMatrix();
    popStyle();
  }

  String getPlayerTypeSummary() {
    String w = gameStatus.enginePlayAsWhite ? "Bot" : "Spieler";
    String b = gameStatus.enginePlayAsBlack ? "Bot" : "Spieler";
    return w + " vs. " + b;
  }

  void drawSettingInfoSummary() {
    if (overlayRenderer.currentAnimation.equals("Checkmate")) return;
    textSize(16);
    textAlign(CENTER);
    String w = gameStatus.enginePlayAsWhite ? "Bot" : "Spieler";
    String b = gameStatus.enginePlayAsBlack ? "Bot" : "Spieler";
    text(w + "/" + b, 512, 270);
    int basePos = 512;
    float offsetOfText = (textWidth(w + "/" + b) / 2.0);
    shape(gameStatus.enginePlayAsWhite ? botIcon : playerIcon, basePos - offsetOfText - 30, 255, 20, 20);
    shape(gameStatus.enginePlayAsBlack ? botIcon : playerIcon, basePos + offsetOfText + 10, 255, 20, 20);
  }

  String formatTime(float seconds) {
    int total = round(seconds);
    return (total / 60) + ":" + nf(total % 60, 2);
  }

  void applySettings() {
    gameStatus.engineMode = pendingEngineMode;
    gameStatus.stockfishElo = pendingElo;
    gameStatus.enginePlayAsWhite = pendingWhiteBot;
    gameStatus.enginePlayAsBlack = pendingBlackBot;
    gameStatus.timeLimit = pendingTimeLimit;
    gameStatus.stockfishMaxThinkingTime = pendingThinkTime;
    closeSettings();
  }

  void drawLabel(String s, float x, float y, float size, color c, int alignH) {
    pushStyle();
    fill(c);
    textSize(size);
    textAlign(alignH, CENTER);
    text(s, x, y);
    popStyle();
  }

  void section(String title) {
    cy += 10;
    pushStyle();
    rectMode(CORNER);
    noStroke();
    fill(ui.accent());
    rect(colX(), cy + 4, 4, 20);
    stroke(ui.inactiveCol);
    strokeWeight(1);
    line(colX(), cy + 32, colX() + colW(), cy + 32);
    popStyle();
    drawLabel(title, colX() + 14, cy + 14, 18, color(255), LEFT);
    cy += 46;
  }

  void infoRow(String left, String right) {
    drawLabel(left, colX(), cy + 10, 15, color(150), LEFT);
    drawLabel(right, colX() + colW(), cy + 10, 15, color(235), RIGHT);
    cy += 28;
  }

  void navEntry(String id, String label, String description, int target) {
    ui.button("nav" + id, label, colX(), cy, colW(), 40, false, LEFT, () -> goTo(target));
    drawLabel(">", colX() + colW() - 16, cy + 20, 15, color(255), RIGHT);
    drawLabel(description, colX() + 4, cy + 54, 13, color(140), LEFT);
    cy += 80;
  }

  void drawContent() {
    targetScroll = constrain(targetScroll, 0, maxScroll());
    scroll = lerp(scroll, targetScroll, scrollEase);
    if (abs(targetScroll - scroll) < 0.3) scroll = targetScroll;

    boolean prevEnabled = ui.enabled;
    ui.enabled = prevEnabled && mouseInView();

    ui.pushOuterClip(viewTop(), viewHeight());

    cy = viewTop() + 16 - scroll;
    float startY = cy;

    if (page == PAGE_HOME) pageHome();
    else if (page == PAGE_GAME) pageGame();
    else if (page == PAGE_LOOK) pageLook();
    else if (page == PAGE_ADVANCED) pageAdvanced();
    else pageCredits();

    cy += 24;
    contentHeight = cy - startY + 16;

    ui.popOuterClip();
    ui.enabled = prevEnabled;
  }

  void pageHome() {
    section("Aktuelle Partie");
    infoRow("Spieler", getPlayerTypeSummary());
    infoRow("Engine", engineNames[constrain(gameStatus.engineMode, 1, 3) - 1]);
    infoRow("Engine-Elo", gameStatus.engineMode == 2 ? str(gameStatus.stockfishElo) : "-");
    infoRow("Zeitlimit", formatTime(gameStatus.timeLimit));

    section("Bereiche");
    navEntry("game", "Spiel", "Spieler, Gegner-Engine und Zeitlimit", PAGE_GAME);
    navEntry("look", "Darstellung", "Brett-Design und Menü-Transparenz", PAGE_LOOK);
    navEntry("adv", "Erweitert", "Bedienung, Stockfish-Denkzeit und Zurücksetzen", PAGE_ADVANCED);

    section("Online");
    pushStyle();
    rectMode(CORNER);
    noFill();
    stroke(ui.inactiveCol);
    strokeWeight(1);
    rect(colX(), cy, colW(), 40);
    popStyle();
    drawLabel("Multiplayer-Lobbies sind bald verfügbar", colX() + 14, cy + 20, 15, color(140), LEFT);
    cy += 56;

    section("Info");
    navEntry("credits", "Credits", "Wer was gebaut hat und wem Dank gebührt", PAGE_CREDITS);
  }

  void pageGame() {
    section("Spieler");
    ui.toggle("whiteBot", "Weiß spielt als Bot", colX(), cy, pendingWhiteBot, (v) -> pendingWhiteBot = v);
    ui.toggle("blackBot", "Schwarz spielt als Bot", colX() + 220, cy, pendingBlackBot, (v) -> pendingBlackBot = v);
    cy += 40;

    section("Gegner-Engine");
    pendingEngineMode = 1 + ui.segmented("engineMode", "Engine", colX(), cy, colW(), engineNames,
      pendingEngineMode - 1, (i) -> pendingEngineMode = i + 1);
    cy += 44;

    if (pendingEngineMode == 2) {
      ui.slider("elo", "Stockfish-Elo", colX(), cy, colW(), 1320, 3200, 10, pendingElo, (v) -> pendingElo = round(v));
    } else {
      ui.label("Engine-Elo", colX(), cy + 6);
      drawLabel(pendingEngineMode == 1 ? "500" : "~", colX() + colW(), cy + 6, 14, color(255), RIGHT);
    }
    cy += 44;

    section("Zeit");
    ui.slider("timeLimit", "Zeitlimit", colX(), cy, colW(), 30, 5400, 30, pendingTimeLimit,
      (v) -> formatTime(v), (v) -> pendingTimeLimit = round(v));
    cy += 44;
  }

  void pageLook() {
    section("Brett");
    ui.designPicker("design", "Brett-Design", colX(), cy, colW(), rendererBaseLayout.designs,
      gameStatus.playingFieldDesign, (i) -> gameStatus.playingFieldDesign = i);
    cy += designPickerH;

    section("Menü");
    ui.slider("panelAlpha", "Einstellungen-Deckkraft", colX(), cy, colW(), 120, 255, 5, panelAlpha,
      (v) -> round(v / 255.0 * 100) + "%", (v) -> panelAlpha = v);
    cy += 44;
  }

  void pageAdvanced() {
    section("Bedienung");
    ui.slider("scrollSens", "Scroll-Geschwindigkeit", colX(), cy, colW(), 0.5, 3, 0.1, scrollSensitivity,
      (v) -> nf(v, 1, 1) + "x", (v) -> scrollSensitivity = v);
    cy += 44;

    section("Stockfish");
    ui.slider("thinkTime", "Denkzeit-Limit", colX(), cy, colW(), 1, 2000, 1, pendingThinkTime,
      (v) -> round(v) + " ms", (v) -> pendingThinkTime = round(v));
    cy += 44;

    section("Zurücksetzen");
    float bw = (colW() - 10) / 2;
    ui.button("discard", "Änderungen verwerfen", colX(), cy, bw, 34, false, () -> loadPending());
    ui.button("defaults", "Standardwerte laden", colX() + bw + 10, cy, bw, 34, false, () -> resetPendingToDefaults());
    cy += 50;
    drawLabel("Beides betrifft nur die ungespeicherten Änderungen, erst Übernehmen wendet sie an.", colX() + 4, cy + 4, 13, color(140), LEFT);
    cy += 30;
  }

  void creditBlock(String title, String[][] rows) {
    section(title);
    for (int i = 0; i < rows.length; i++) infoRow(rows[i][0], rows[i][1]);
  }

  ArrayList<String> wrapText(String s, float maxW) {
    ArrayList<String> lines = new ArrayList<String>();
    String[] segments = split(s, '\n');
    pushStyle();
    textSize(15);
    for (int i = 0; i < segments.length; i++) {
      String[] words = splitTokens(segments[i], " ");
      String line = "";
      for (int j = 0; j < words.length; j++) {
        String test = line.length() == 0 ? words[j] : line + " " + words[j];
        if (textWidth(test) > maxW && line.length() > 0) {
          lines.add(line);
          line = words[j];
        } else {
          line = test;
        }
      }
      lines.add(line);
    }
    popStyle();
    return lines;
  }

  void paragraph(String s) {
    ArrayList<String> lines = wrapText(s, colW() - 8);
    for (int i = 0; i < lines.size(); i++) {
      drawLabel(lines.get(i), colX() + 4, cy + 11, 15, color(200), LEFT);
      cy += 22;
    }
    cy += 10;
  }

  void pageCredits() {
    creditBlock("Projekt", creditsProject);
    creditBlock("Engines", creditsEngines);
    creditBlock("Technik", creditsTech);
    creditBlock("Dank an", creditsThanks);
    section("Generative KI-Nutzung");
    for (int i = 0; i < creditsAi.length; i++) paragraph(creditsAi[i]);
  }

  void drawHeader() {
    pushStyle();
    rectMode(CORNER);
    noStroke();
    fill(0, 0, 0, 90);
    rect(0, 0, width, headerH);
    stroke(ui.inactiveCol);
    strokeWeight(1);
    line(0, headerH, width, headerH);
    popStyle();

    float by = (headerH - 34) / 2;
    float titleX = colX();

    if (page != PAGE_HOME) {
      ui.button("back", "< Zurück", colX(), by, 110, 34, false, () -> goTo(PAGE_HOME));
      titleX = colX() + 130;
    }

    drawLabel(pageTitles[page], titleX, headerH / 2, 24, color(255), LEFT);

    ui.button("close", "Schließen", colX() + colW() - 110, by, 110, 34, false, () -> closeSettings());
  }

  void drawFooter() {
    pushStyle();
    rectMode(CORNER);
    noStroke();
    fill(0, 0, 0, 90);
    rect(0, viewBottom(), width, footerH);
    stroke(ui.inactiveCol);
    strokeWeight(1);
    line(0, viewBottom(), width, viewBottom());
    popStyle();

    float by = viewBottom() + (footerH - 34) / 2;
    float bw = (colW() - 10) / 2;
    ui.button("apply", "Übernehmen", colX(), by, bw, 34, true, () -> overlayRenderer.startConfirmSetting());
    ui.button("restart", "Neues Spiel", colX() + bw + 10, by, bw, 34, false, () -> {
      closeSettings();
      overlayRenderer.newGameCalled();
    }
    );
  }

  void drawScrollbar() {
    float ms = maxScroll();
    if (ms <= 0) return;
    float trackX = width - 12;
    float thumbH = max(30, viewHeight() * viewHeight() / contentHeight);
    float thumbY = viewTop() + (scroll / ms) * (viewHeight() - thumbH);
    pushStyle();
    rectMode(CORNER);
    noStroke();
    fill(ui.inactiveCol, 120);
    rect(trackX, viewTop(), 6, viewHeight());
    fill(ui.accent());
    rect(trackX, thumbY, 6, thumbH);
    popStyle();
  }

  void drawSettingsFrame() {
    pushStyle();
    rectMode(CORNER);
    noStroke();
    fill(10, 10, 10, panelAlpha);
    rect(0, 0, width, height);
    popStyle();

    drawContent();
    drawHeader();
    drawFooter();
    drawScrollbar();
  }
}
