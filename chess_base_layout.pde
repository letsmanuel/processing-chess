GameStatus gameStatus = new GameStatus();
RendererBaseLayout rendererBaseLayout = new RendererBaseLayout();
PieceRenderer pieceRenderer = new PieceRenderer();
LegalMoves legalMovesEngine = new LegalMoves(gameStatus);
OverlayRenderer overlayRenderer = new OverlayRenderer();
PositionEvaluator positionEvaluator = new PositionEvaluator();
ChessEngine chessEngine = new ChessEngine(gameStatus, legalMovesEngine, positionEvaluator);
SoundManager soundManager;
PowerBarRenderer powerBarRenderer = new PowerBarRenderer();
SettingsRenderer settingsRenderer = new SettingsRenderer();
TimeRenderer timeRenderer = new TimeRenderer();
LastMoveListRenderer lastMoveListRenderer = new LastMoveListRenderer();
MoveRating moveRating = new MoveRating();
SystemSpecifications systemSpecs = new SystemSpecifications();

GameStatus searchStatus = new GameStatus();
LegalMoves searchLegal = new LegalMoves(searchStatus);
ChessEngine searchEngine = new ChessEngine(searchStatus, searchLegal, new PositionEvaluator());

StockfishBridge stockfish = new StockfishBridge();
boolean smartMode = false;
int stockfishMoveTimeMs = 500;
int stockfishElo = 3200;

volatile boolean engineThinking = false;
volatile boolean engineResultReady = false;
volatile int[] engineResult = null;
boolean searchWhite = true;
int searchGameID = 0;
int engineDepth = 8;

int selectedFieldID = -1;
int[] legalMoveIDs = new int[0];

boolean whiteTurn = true;
boolean printLegalMoves = false;
boolean gameOver = false;
int drawTick = 0;


void setup() {
  size(600, 400);
  windowTitle("Chess.Processing "+gameStatus.engineVersion+" startet.");

  PImage icon = loadImage("images/window-icon.png");
  surface.setIcon(icon);
  PShape loadingShape = loadShape("pieces/black_king.svg");
  shape(loadingShape, (width/2) - 100, (height/2)-150, 200, 200);
  textSize(50);
  fill(0, 0, 0);
  text("CHESS.PROCESSING", (width/2) - (textWidth("CHESS.PROCESSING") / 2), (height/2)+100);
  textSize(15);
  text("© Paul Stiassny", 10, height - 20);

  pieceRenderer.init();
  overlayRenderer.init();
  chessEngine.resetPositionHistory(whiteTurn);
  soundManager = new SoundManager(this);
  settingsRenderer.init();
  lastMoveListRenderer.init();
  moveRating.init(whiteTurn);
}

boolean stockfishStartTried = false;
boolean lastMoveFromStockfish = false;

void tickEngineSettings() {
  stockfishElo = gameStatus.stockfishElo;

  if (gameStatus.engineMode == 1) smartMode = false;
  if (gameStatus.engineMode == 2) {
    smartMode = true;
    if (!stockfish.ready && !stockfishStartTried) {
      stockfishStartTried = true;
      systemSpecs.setGameStatusStockfishPath();
      if (stockfish.start(dataPath(gameStatus.stockfishPath), 2, 64)) {
        stockfish.setStrength(stockfishElo);
      } else {
        println("Stockfish not started: " + stockfish.lastError);
        overlayRenderer.startWarningStockfishError();
      }
    }
  }
}


void draw() {
  drawTick++;
  if (drawTick == 100) settingsRenderer.rotateBy(PI);
  if (drawTick == 200) settingsRenderer.rotateBy(PI);
  stockfishMoveTimeMs = gameStatus.stockfishMaxThinkingTime;
  if (drawTick % 100 == 0) {
    String linuxAppend = gameStatus.isLinux ? " (Linux)":"(Windows)";
    String playerTypeAppend = "";
    if (!gameStatus.currentlyInCheck) playerTypeAppend = "     > "+settingsRenderer.getPlayerTypeSummary()+" <";
    if (gameStatus.currentlyInCheck) playerTypeAppend = "     > Schachmatt! <";
    windowTitle("Chess.Processing "+gameStatus.engineVersion+linuxAppend+playerTypeAppend);
  }
  handleSoundQueue();
  applyEngineResult();
  tickEngineSettings();
  rendererBaseLayout.drawPlayingField(gameStatus.playingFieldDesign, selectedFieldID);
  if (!overlayRenderer.pauseGameDueToAnimation) {
    int[][] allMoves = legalMovesEngine.getAllLegalMovesArray(
      whiteTurn, printLegalMoves
      );

    if (allMoves.length == 0) {
      gameOver = true;
      selectedFieldID = -1;
      legalMoveIDs = new int[0];

      if (legalMovesEngine.isKingInCheck(whiteTurn)) {
        gameStatus.soundQueue = append(gameStatus.soundQueue, "check");
        overlayRenderer.winnerIsWhite = !whiteTurn;
        println(!whiteTurn);
        overlayRenderer.drawCheckmate();
      }
    }

    if (gameStatus.halfMoveCounter > 149) {
      //schach rules halt
      gameStatus.isDrawCurrently = true;
      gameStatus.soundQueue = append(gameStatus.soundQueue, "check");
      overlayRenderer.winnerIsWhite = false; // ist egal tbh
      overlayRenderer.drawCheckmate();
    }




    if (gameOver) {
      legalMoveIDs = new int[0];
    } else if (selectedFieldID != -1) {
      legalMoveIDs = legalMovesEngine.getLegalMoves(selectedFieldID);
    } else {
      legalMoveIDs = new int[0];
    }

    gameStatus.currentlyInCheck = legalMovesEngine.isKingInCheck(whiteTurn);
  }
  rendererBaseLayout.drawLegalMoves(
    gameStatus.playingFieldDesign,
    selectedFieldID,
    legalMoveIDs
    );

  pieceRenderer.drawPieces(gameStatus.fieldObject);

  if (drawTick % 60 == 0 && gameStatus.firstMoveDone && !overlayRenderer.pauseGameDueToAnimation) {
    if (whiteTurn) gameStatus.timeLimitWhite--;
    if (!whiteTurn) gameStatus.timeLimitBlack--;
  }

  fill(255);
  textSize(25);
  textAlign(LEFT, TOP);
  timeRenderer.tickTimes(gameStatus.timeLimitWhite, gameStatus.timeLimitBlack, whiteTurn, gameStatus);

  if (engineThinking) {
    fill(255);
    textSize(16);
    textAlign(LEFT, TOP);
    if (whiteTurn) {
      text("denkt...", 486, 377);
    } else {
      text("denkt...", 486, 17);
    }
  }

  if (gameStatus.promotionChoice > 0) {
    legalMovesEngine.completePromotion();
  }

  moveRating.tickRatings();

  powerBarRenderer.drawPowerBar(positionEvaluator.getCurrentEval(gameStatus.fieldObject));

  lastMoveListRenderer.tickLastMoves();

  settingsRenderer.drawSettingInfoSummary();

  settingsRenderer.tickSettings();

  overlayRenderer.tickOverlays();

  if (whiteTurn && gameStatus.enginePlayAsWhite) startEngineSearch();
  if (!whiteTurn && gameStatus.enginePlayAsBlack) startEngineSearch();
}

void startEngineSearch() {
  if (engineThinking || gameOver) return;
  if (overlayRenderer.pauseGameDueToAnimation) return;

  for (int row = 0; row < 8; row++) {
    System.arraycopy(gameStatus.fieldObject[row], 0, searchStatus.fieldObject[row], 0, 8);
  }

  searchLegal.enPassantTarget = legalMovesEngine.enPassantTarget;
  searchLegal.enPassantPawnField = legalMovesEngine.enPassantPawnField;
  searchLegal.whiteKingSide = legalMovesEngine.whiteKingSide;
  searchLegal.whiteQueenSide = legalMovesEngine.whiteQueenSide;
  searchLegal.blackKingSide = legalMovesEngine.blackKingSide;
  searchLegal.blackQueenSide = legalMovesEngine.blackQueenSide;

  searchEngine.positionHistory.clear();
  searchEngine.positionHistory.putAll(chessEngine.positionHistory);

  searchWhite = whiteTurn;
  searchGameID = gameStatus.gameID;
  searchStatus.gameID = gameStatus.gameID;
  engineResult = null;
  engineResultReady = false;
  engineThinking = true;

  thread("runEngineSearch");
}

void runEngineSearch() {
  int[] move = null;

  try {
    if (smartMode && stockfish.ready) {
      String fen = stockfish.buildFen(searchStatus.fieldObject, searchWhite,
        searchLegal.whiteKingSide, searchLegal.whiteQueenSide,
        searchLegal.blackKingSide, searchLegal.blackQueenSide,
        searchLegal.enPassantTarget);
      move = stockfish.bestMove(fen, stockfishMoveTimeMs);
    }

    if (move == null) {
      move = searchEngine.findBestMove(searchWhite, engineDepth, searchGameID);
    }
  }
  catch (Exception e) {
    e.printStackTrace();
  }

  engineResult = move;
  engineResultReady = true;
}
void applyEngineResult() {
  if (!engineResultReady) return;

  engineResultReady = false;
  engineThinking = false;

  int[] move = engineResult;

  if (smartMode) println("Stockfish depth " + stockfish.lastDepth + "  score " + stockfish.lastScore);
  else println("depth " + searchEngine.lastDepthReached + "  nodes " + searchEngine.nodesSearched + "  score " + searchEngine.lastScore);

  if (move == null) {
    println("No legal moves found.");
    return;
  }

  if (searchGameID != gameStatus.gameID || gameOver) return;

  if (chessEngine.updateMoves(move[0], move[1])) {
    selectedFieldID = -1;
    gameStatus.soundQueue = append(gameStatus.soundQueue, "move");
    legalMoveIDs = new int[0];
    whiteTurn = !whiteTurn;
    chessEngine.recordPosition(whiteTurn);
  } else {
    println("Engine returned an invalid move!");
  }
}

void mousePressed() {
  if (mouseX > settingsRenderer.iconX
    && mouseX < settingsRenderer.iconX + settingsRenderer.baseSize - 5
    && mouseY > settingsRenderer.iconY
    && mouseY < settingsRenderer.iconY + settingsRenderer.baseSize - 5) {
    settingsRenderer.settingsOpen = !settingsRenderer.settingsOpen;
    gameStatus.soundQueue = append(gameStatus.soundQueue, "click");
  }

  if (settingsRenderer.settingsOpen) settingsRenderer.onMousePressed();
  
  if (overlayRenderer.pauseGameDueToAnimation) {
    buttonRenderer.handleMousePressed();

    return;
  }

  if (settingsRenderer.settingsOpen) return;

  if (engineThinking) return;

  int elementSize = rendererBaseLayout.elementSize;

  if (mouseX < 0 || mouseY < 0 ||
    mouseX >= elementSize * 8 ||
    mouseY >= elementSize * 8) {
    return;
  }

  int col = mouseX / elementSize;
  int row = mouseY / elementSize;
  int clickedFieldID = row * 8 + col;

  int clickedPiece = gameStatus.fieldObject[row][col];

  if (selectedFieldID != -1) {
    legalMoveIDs = legalMovesEngine.getLegalMoves(selectedFieldID);

    if (containsField(legalMoveIDs, clickedFieldID)) {
      if (legalMovesEngine.makeMove(selectedFieldID, clickedFieldID, true)) {
        gameStatus.soundQueue = append(gameStatus.soundQueue, "move");
        selectedFieldID = -1;
        legalMoveIDs = new int[0];
        whiteTurn = !whiteTurn;
        chessEngine.recordPosition(whiteTurn);
      }

      return;
    }
  }

  if (clickedPiece != 0 &&
    legalMovesEngine.isWhitePiece(clickedPiece) == whiteTurn) {
    selectedFieldID = clickedFieldID;
    legalMoveIDs = legalMovesEngine.getLegalMoves(selectedFieldID);
  } else {
    selectedFieldID = -1;
    legalMoveIDs = new int[0];
  }
}

boolean containsField(int[] fields, int fieldID) {
  for (int field : fields) {
    if (field == fieldID) {
      return true;
    }
  }

  return false;
}

void handleSoundQueue() {
  for (int i = 0; i < gameStatus.soundQueue.length; i++) {
    soundManager.playSoundById(gameStatus.soundQueue[i]);
  }
  gameStatus.soundQueue = new String[0];
}


void keyPressed() {
  if (settingsRenderer.settingsOpen) settingsRenderer.onKeyPressed();
  if (key == CODED && keyCode == SHIFT) gameStatus.shiftDown = true;
}

void keyReleased() {
  if (key == CODED && keyCode == SHIFT) gameStatus.shiftDown = false;
}


void mouseWheel(MouseEvent event) {
  settingsRenderer.onMouseWheel(event.getCount());
}
