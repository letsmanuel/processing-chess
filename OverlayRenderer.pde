ButtonRenderer buttonRenderer = new ButtonRenderer();

class OverlayRenderer {

  boolean pauseGameDueToAnimation = false;
  int animationBegin = 0;
  String currentAnimation = "";

  PShape checkSweatEmoji;
  PShape brokenWhiteKing;

  boolean winnerIsWhite = false;
  boolean promotionIsWhite = true;

  int[][] initFieldObject = {
    {8, 9, 10, 11, 12, 10, 9, 8},
    {7, 7, 7, 7, 7, 7, 7, 7},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {1, 1, 1, 1, 1, 1, 1, 1},
    {2, 3, 4, 5, 6, 4, 3, 2}
  };

  void init() {
    checkSweatEmoji = loadShape("overlay-assets/sweat.svg");
    brokenWhiteKing = loadShape("overlay-assets/broken-white-king.svg");
  }

  void drawCheckmate() {
    if (currentAnimation.equals("Checkmate")) return;

    animationBegin = millis();
    pauseGameDueToAnimation = true;
    currentAnimation = "Checkmate";

    int margin = 400 / 6;
    int panelX = margin;
    int panelY = margin;

    int buttonWidth = 140;
    int buttonHeight = 40;
    int startX = panelX + 30;
    int startY = panelY + 205;
    gameStatus.soundQueue = append(gameStatus.soundQueue, "gameEnd");
    buttonRenderer.createNewButton("Neues Spiel", 17, startX, startY, buttonWidth, buttonHeight, () -> newGameCalled());
    //newGameCalled(); // instant neustart für stats holen und so
  }

  void newGameCalled() {
    buttonRenderer.removeAllButtons();

    for (int row = 0; row < 8; row++) {
      System.arraycopy(initFieldObject[row], 0, gameStatus.fieldObject[row], 0, 8);
    }

    legalMovesEngine.enPassantTarget = -1;
    legalMovesEngine.enPassantPawnField = -1;
    legalMovesEngine.whiteKingSide = true;
    legalMovesEngine.whiteQueenSide = true;
    legalMovesEngine.blackKingSide = true;
    legalMovesEngine.blackQueenSide = true;
    legalMovesEngine.promotionPending = false;
    legalMovesEngine.promotionField = -1;
    legalMovesEngine.promotionPawn = 0;
    gameStatus.isDrawCurrently = false;
    gameStatus.halfMoveCounter = 0;

    gameStatus.promotionChoice = 0;
    gameStatus.promotionPending = false;
    gameStatus.soundQueue = new String[0];
    gameStatus.gameID++;
    gameStatus.firstMoveDone = false;
    gameStatus.lastMoveFrom = -1;
    gameStatus.lastMoveTo = -1;
    moveRating.reset(true);
    gameStatus.timeLimitWhite = gameStatus.timeLimit;
    gameStatus.timeLimitBlack = gameStatus.timeLimit;
    lastMoveListRenderer.clearLastMoves();
    chessEngine.searchHistory.clear();

    whiteTurn = true;
    gameOver = false;
    selectedFieldID = -1;
    legalMoveIDs = new int[0];

    chessEngine.resetPositionHistory(true);

    pauseGameDueToAnimation = false;
    currentAnimation = "";
  }

  void startPromotion(boolean whitePawn) {
    buttonRenderer.removeAllButtons();

    gameStatus.promotionChoice = 0;
    promotionIsWhite = whitePawn;
    animationBegin = millis();
    pauseGameDueToAnimation = true;
    currentAnimation = "Promotion";

    int queen = whitePawn ? 5 : 11;
    int rook = whitePawn ? 2 : 8;
    int bishop = whitePawn ? 4 : 10;
    int knight = whitePawn ? 3 : 9;

    int margin = 400 / 6;
    int panelX = margin;
    int panelY = margin;
    int panelWidth = 400 - margin * 2;
    int panelHeight = 400 - margin * 2;

    int buttonWidth = 85;
    int buttonHeight = 48;
    int gap = 10;

    int startX = panelX + (panelWidth - buttonWidth * 2 - gap) / 2;
    int startY = panelY + 105;

    buttonRenderer.createNewButton("Königin", 17, startX, startY, buttonWidth, buttonHeight, () -> choosePromotion(queen));
    buttonRenderer.createNewButton("Turm", 17, startX + buttonWidth + gap, startY, buttonWidth, buttonHeight, () -> choosePromotion(rook));
    buttonRenderer.createNewButton("Läufer", 17, startX, startY + buttonHeight + gap, buttonWidth, buttonHeight, () -> choosePromotion(bishop));
    buttonRenderer.createNewButton("Springer", 17, startX + buttonWidth + gap, startY + buttonHeight + gap, buttonWidth, buttonHeight, () -> choosePromotion(knight));
  }

  void choosePromotion(int pieceID) {
    if (!currentAnimation.equals("Promotion")) return;

    gameStatus.promotionChoice = pieceID;
    buttonRenderer.removeAllButtons();

    currentAnimation = "";
    pauseGameDueToAnimation = false;
  }


  void startConfirmSetting() {
    if (pauseGameDueToAnimation) return;

    buttonRenderer.removeAllButtons();
    animationBegin = millis();
    pauseGameDueToAnimation = true;
    currentAnimation = "ConfirmSetting";

    int margin = 400 / 6;
    int panelX = margin;
    int panelY = margin;
    int panelWidth = 400 - margin * 2;

    int buttonWidth = 100;
    int buttonHeight = 44;
    int gap = 10;

    int startX = panelX + (panelWidth - buttonWidth * 2 - gap) / 2;
    int startY = panelY + 170;

    buttonRenderer.createNewButton("Ja", 17, startX, startY, buttonWidth, buttonHeight, () -> confirmSettingYes());
    buttonRenderer.createNewButton("Nein", 17, startX + buttonWidth + gap, startY, buttonWidth, buttonHeight, () -> confirmSettingNo());
  }

  void startWarningStockfishError() {
    if (pauseGameDueToAnimation) return;

    buttonRenderer.removeAllButtons();
    animationBegin = millis();
    pauseGameDueToAnimation = true;
    currentAnimation = "StockfishError";

    int margin = 400 / 6;
    int panelX = margin;
    int panelY = margin;
    int panelWidth = 400 - margin * 2;

    int buttonWidth = 100;
    int buttonHeight = 44;
    int gap = 10;

    int startX = panelX + (panelWidth - buttonWidth * 2 - gap) / 2;
    int startY = panelY + 170;

    buttonRenderer.createNewButton("Ok", 17, startX, startY, buttonWidth, buttonHeight, () -> closeOverlay());
    buttonRenderer.createNewButton("Beenden", 17, startX + buttonWidth + gap, startY, buttonWidth, buttonHeight, () -> exit());
  }

  void confirmSettingYes() {
    if (!currentAnimation.equals("ConfirmSetting")) return;

    settingsRenderer.applySettings();
    newGameCalled();
  }

  void confirmSettingNo() {
    if (!currentAnimation.equals("ConfirmSetting")) return;

    buttonRenderer.removeAllButtons();
    currentAnimation = "";
    pauseGameDueToAnimation = false;
  }

  void closeOverlay() {
    buttonRenderer.removeAllButtons();
    currentAnimation = "";
    pauseGameDueToAnimation = false;
  }


  void tickOverlays() {
    if (!pauseGameDueToAnimation || currentAnimation.length() == 0) return;

    int margin = 400 / 6;
    int panelX = margin;
    int panelY = margin;
    int panelWidth = 400 - margin * 2;
    int panelHeight = 400 - margin * 2;

    switch (currentAnimation) {
    case "Checkmate":
      if (settingsRenderer.settingsOpen) return;
      if (gameStatus.shiftDown) return;
      if (gameStatus.isDrawCurrently) {
        rectMode(CORNER);
        strokeWeight(4);
        stroke(0);
        fill(35, 40, 55);
        rect(panelX, panelY, panelWidth, panelHeight, 16);
        if (checkSweatEmoji != null) {
          shape(checkSweatEmoji, panelX + 20, panelY + 20, 50, 50);
        }

        fill(255);
        textAlign(LEFT, CENTER);
        textSize(25);
        text("REMIS", panelX + 85, panelY + 32);

        textSize(40);
        buttonRenderer.tickAllButtons();
        return;
      }
      rectMode(CORNER);
      strokeWeight(4);
      stroke(0);
      fill(35, 40, 55);
      rect(panelX, panelY, panelWidth, panelHeight, 16);
      if (checkSweatEmoji != null) {
        shape(checkSweatEmoji, panelX + 20, panelY + 20, 50, 50);
      }

      fill(255);
      textAlign(LEFT, CENTER);
      textSize(25);
      text("SCHACHMATT", panelX + 85, panelY + 32);

      textSize(40);
      text(winnerIsWhite ? "WEISS" : "SCHWARZ", panelX + 30, panelY + 125);

      textSize(20);
      text("gewinnt", panelX + 30, panelY + 175);
      buttonRenderer.tickAllButtons();
      break;

    case "Promotion":
      if (settingsRenderer.settingsOpen) return;
      rectMode(CORNER);
      strokeWeight(4);
      stroke(0);
      fill(35, 40, 55);
      rect(panelX, panelY, panelWidth, panelHeight, 16);
      fill(255);
      textAlign(CENTER, CENTER);
      textSize(22);
      text("Umwandlung", panelX + panelWidth / 2, panelY + 28);

      textSize(14);
      fill(195, 205, 220);
      text("Wähle eine Figur", panelX + panelWidth / 2, panelY + 58);

      buttonRenderer.tickAllButtons();
      break;

    case "ConfirmSetting":
      rectMode(CORNER);
      strokeWeight(4);
      stroke(0);
      fill(35, 40, 55);
      rect(panelX, panelY, panelWidth, panelHeight, 16);
      fill(255);
      textAlign(CENTER, CENTER);
      textSize(24);
      text("Einstellungen", panelX + panelWidth / 2, panelY + 30);
      text("übernehmen?", panelX + panelWidth / 2, panelY + 60);

      textSize(14);
      fill(195, 205, 220);
      text("Das Spiel wird dabei", panelX + panelWidth / 2, panelY + 108);
      text("neu gestartet.", panelX + panelWidth / 2, panelY + 128);

      buttonRenderer.tickAllButtons();
      break;

    case "StockfishError":
      rectMode(CORNER);
      strokeWeight(4);
      stroke(0);
      fill(35, 40, 55);
      rect(panelX, panelY, panelWidth, panelHeight, 16);
      fill(255);
      textAlign(CENTER, CENTER);
      textSize(24);
      text("Fehler", panelX + panelWidth / 2, panelY + 30);
      text("beim starten.", panelX + panelWidth / 2, panelY + 60);

      textSize(14);
      fill(195, 205, 220);
      text("Stockfish wurde nicht", panelX + panelWidth / 2, panelY + 108);
      text("gestartet. Engine ist 'Experimentell'", panelX + panelWidth / 2, panelY + 128);

      buttonRenderer.tickAllButtons();
      break;
    }
  }
}
