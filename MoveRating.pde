import java.util.ArrayList;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

class MoveRating {

  int analysisDepth = 4;
  int analysisTimeMs = 60;
  int scanDepth = 2;
  int scanTimeMs = 20;

  int maxEngines = max(1, min(3, Runtime.getRuntime().availableProcessors() - 1));
  int idleSecondsBeforeRetire = 10;
  boolean pauseWhileEngineThinks = true;
  boolean debugShowAll = false;

  int skipOpeningPlies = 4;
  float bestLoss = 0.03f;
  float inaccuracyLoss = 0.08f;
  float mistakeLoss = 0.15f;
  float blunderLoss = 0.25f;
  float onlyMoveMargin = 0.20f;

  final int MATE = 100000;

  Object lock = new Object();
  ArrayList<Position> positions = new ArrayList<Position>();
  ArrayList<Integer> scores = new ArrayList<Integer>();
  ArrayList<RatedMove> moves = new ArrayList<RatedMove>();
  LinkedBlockingQueue<int[]> queue = new LinkedBlockingQueue<int[]>();
  volatile int generation = 0;

  AtomicInteger workerCount = new AtomicInteger(0);
  AtomicInteger idle = new AtomicInteger(0);

  int pendingFrom = -1;
  int pendingTo = -1;
  boolean pendingWhiteToMove = true;

  RatedMove leavingMove = null;
  int leaveStart = 0;

  class Position {
    int[][] board = new int[8][8];
    int enPassantTarget;
    int enPassantPawnField;
    boolean whiteKingSide;
    boolean whiteQueenSide;
    boolean blackKingSide;
    boolean blackQueenSide;
    boolean whiteToMove;
    int gameID;
  }

  class RatedMove {
    int from;
    int toPOS;
    boolean moverWhite;
    int captured;
    boolean claimed = false;
    volatile String symbol = "";
    volatile boolean rated = false;
    int popStart = -1;

    RatedMove(int from, int toPOS, boolean moverWhite, int captured) {
      this.from = from;
      this.toPOS = toPOS;
      this.moverWhite = moverWhite;
      this.captured = captured;
    }
  }

  void init(boolean whiteToMove) {
    reset(whiteToMove);
  }

  void reset(boolean whiteToMove) {
    synchronized (lock) {
      generation++;
      positions.clear();
      scores.clear();
      moves.clear();
      queue.clear();
    }

    pendingFrom = -1;
    leavingMove = null;

    submitPosition(snapshotLive(whiteToMove));
  }

  void moveMade(int from, int toPOS, boolean whiteToMoveNow) {
    if (legalMovesEngine.promotionPending) {
      pendingFrom = from;
      pendingTo = toPOS;
      pendingWhiteToMove = whiteToMoveNow;
      return;
    }

    commitMove(from, toPOS, whiteToMoveNow);
  }

  String getSymbol(int moveIndex) {
    synchronized (lock) {
      if (moveIndex < 0 || moveIndex >= moves.size()) return "";
      return moves.get(moveIndex).symbol;
    }
  }

  color getSymbolColor(String symbol) {
    if (symbol.equals("!!")) return color(27, 172, 166);
    if (symbol.equals("!")) return color(92, 139, 176);
    if (symbol.equals("?!")) return color(247, 198, 49);
    if (symbol.equals("?")) return color(229, 143, 42);
    if (symbol.equals("??")) return color(202, 52, 49);
    return color(150);
  }

  void tickRatings() {
    if (pendingFrom >= 0 && !legalMovesEngine.promotionPending) {
      commitMove(pendingFrom, pendingTo, pendingWhiteToMove);
      pendingFrom = -1;
    }

    int now = millis();

    if (leavingMove != null) {
      float t = (now - leaveStart) / 150.0f;

      if (t >= 1) {
        leavingMove = null;
      } else {
        drawBadge(leavingMove, 1 - t);
      }
    }

    RatedMove latest = latestMove();

    if (latest != null && latest.rated && latest.symbol.length() > 0) {
      if (latest.popStart < 0) latest.popStart = now;

      float t = constrain((now - latest.popStart) / 260.0f, 0, 1);
      drawBadge(latest, easeOutBack(t));
    }
  }

  void drawBadge(RatedMove move, float scale) {
    if (scale <= 0.02) return;

    int size = rendererBaseLayout.elementSize;
    float radius = size * 0.22f;

    float cx = (move.toPOS % 8 + 1) * size - radius * 0.9f;
    float cy = (move.toPOS / 8) * size + radius * 0.9f;

    pushStyle();

    stroke(0, 90);
    strokeWeight(1.5);
    fill(getSymbolColor(move.symbol));
    ellipseMode(CENTER);
    ellipse(cx, cy, radius * 2 * scale, radius * 2 * scale);

    if (scale > 0.5) {
      fill(255);
      noStroke();
      textAlign(CENTER, CENTER);
      textSize(radius * 1.1f * scale);
      text(move.symbol, cx, cy - 1);
    }

    popStyle();
  }

  float easeOutBack(float t) {
    float c1 = 1.70158f;
    float c3 = c1 + 1;
    return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2);
  }

  RatedMove latestMove() {
    synchronized (lock) {
      if (moves.size() == 0) return null;
      return moves.get(moves.size() - 1);
    }
  }

  void commitMove(int from, int toPOS, boolean whiteToMoveNow) {
    Position prev;

    synchronized (lock) {
      if (positions.size() == 0) return;
      prev = positions.get(positions.size() - 1);
    }

    int piece = prev.board[from / 8][from % 8];
    int captured = prev.board[toPOS / 8][toPOS % 8];

    if ((piece == 1 || piece == 7) && captured == 0 && from % 8 != toPOS % 8) {
      captured = piece == 1 ? 7 : 1;
    }

    RatedMove previousLatest = latestMove();

    if (previousLatest != null && previousLatest.popStart >= 0
      && previousLatest.symbol.length() > 0) {
      leavingMove = previousLatest;
      leaveStart = millis();
    }

    RatedMove move = new RatedMove(from, toPOS, !whiteToMoveNow, captured);
    Position after = snapshotLive(whiteToMoveNow);

    synchronized (lock) {
      moves.add(move);
    }

    submitPosition(after);
  }

  void submitPosition(Position position) {
    synchronized (lock) {
      positions.add(position);
      scores.add(null);
      queue.add(new int[] {positions.size() - 1, generation});
    }

    ensureWorkers();
  }

  void ensureWorkers() {
    if (queue.isEmpty()) return;
    if (idle.get() > 0) return;

    if (workerCount.incrementAndGet() > maxEngines) {
      workerCount.decrementAndGet();
      return;
    }

    Thread t = new Thread(() -> new Analyzer().run());
    t.setDaemon(true);
    t.start();
  }

  Position snapshotLive(boolean whiteToMove) {
    return capture(gameStatus.fieldObject, legalMovesEngine, whiteToMove, gameStatus.gameID);
  }

  Position capture(int[][] board, LegalMoves legal, boolean whiteToMove, int gameID) {
    Position p = new Position();

    for (int row = 0; row < 8; row++) {
      System.arraycopy(board[row], 0, p.board[row], 0, 8);
    }

    p.enPassantTarget = legal.enPassantTarget;
    p.enPassantPawnField = legal.enPassantPawnField;
    p.whiteKingSide = legal.whiteKingSide;
    p.whiteQueenSide = legal.whiteQueenSide;
    p.blackKingSide = legal.blackKingSide;
    p.blackQueenSide = legal.blackQueenSide;
    p.whiteToMove = whiteToMove;
    p.gameID = gameID;

    return p;
  }

  int pieceValue(int p) {
    if (p == 0) return 0;

    switch ((p - 1) % 6) {
    case 0:
      return 100;
    case 1:
      return 500;
    case 2:
      return 320;
    case 3:
      return 330;
    case 4:
      return 900;
    default:
      return 20000;
    }
  }

  float winChance(int cp) {
    if (cp >= 99000) return 1;
    if (cp <= -99000) return 0;
    return 1.0f / (1.0f + exp(-0.00368f * cp));
  }

  class Analyzer {

    GameStatus analysisStatus = new GameStatus();
    LegalMoves analysisLegal = new LegalMoves(analysisStatus);
    ChessEngine analysisEngine = new ChessEngine(analysisStatus, analysisLegal, new PositionEvaluator());

    void run() {
      try {
        while (true) {
          int[] job;

          idle.incrementAndGet();
          try {
            job = queue.poll(idleSecondsBeforeRetire, TimeUnit.SECONDS);
          }
          finally {
            idle.decrementAndGet();
          }

          if (job == null) break;

          try {
            while (pauseWhileEngineThinks && engineThinking && job[1] == generation) {
              Thread.sleep(40);
            }

            if (job[1] != generation) continue;

            process(job[0], job[1]);
          }
          catch (InterruptedException e) {
            return;
          }
          catch (Exception e) {
            e.printStackTrace();
          }
        }
      }
      catch (InterruptedException e) {
      }
      finally {
        workerCount.decrementAndGet();
        ensureWorkers();
      }
    }

    void process(int index, int gen) {
      Position pos;

      synchronized (lock) {
        if (gen != generation || index >= positions.size()) return;
        pos = positions.get(index);
      }

      loadPosition(pos);
      int score = scorePosition(pos.whiteToMove, analysisDepth, analysisTimeMs, pos.gameID, 0);

      synchronized (lock) {
        if (gen != generation) return;
        scores.set(index, score);
      }

      tryRate(index - 1, gen);
      tryRate(index, gen);
    }

    void tryRate(int m, int gen) {
      RatedMove move;
      Position before;
      Position after;
      int scoreBefore;
      int scoreAfter;

      synchronized (lock) {
        if (gen != generation || m < 0) return;
        if (m >= moves.size() || m + 1 >= positions.size()) return;

        move = moves.get(m);
        if (move.claimed) return;

        Integer a = scores.get(m);
        Integer b = scores.get(m + 1);
        if (a == null || b == null) return;

        move.claimed = true;
        before = positions.get(m);
        after = positions.get(m + 1);
        scoreBefore = a;
        scoreAfter = b;
      }

      float winBefore = winChance(scoreBefore);
      float winAfter = winChance(-scoreAfter);
      float loss = max(0, winBefore - winAfter);

      String symbol = "";

      if (loss < bestLoss) {
        loadPosition(after);
        boolean sacrifice = isSacrifice(move);

        if (winBefore < 0.9f && winAfter >= 0.45f && sacrifice) {
          symbol = "!!";
        } else if (winBefore < 0.9f && isOnlyMove(before, move, gen)) {
          symbol = "!";
        }
      } else if (m >= skipOpeningPlies) {
        if (loss >= blunderLoss) symbol = "??";
        else if (loss >= mistakeLoss) symbol = "?";
        else if (loss >= inaccuracyLoss) symbol = "?!";
      }

      if (gen != generation) return;

      if (symbol.length() != 0) {
        gameStatus.soundQueue = append(gameStatus.soundQueue, "notify");
      }

      if (debugShowAll) {
        println("rated move " + m + "  loss " + nf(loss, 1, 3) + "  symbol '" + symbol + "'");
        if (symbol.length() == 0) symbol = "ok";
      }

      move.symbol = symbol;
      move.rated = true;
    }

    int scorePosition(boolean white, int depth, int timeMs, int gameID, int chain) {
      ArrayList<int[]> legal = analysisLegal.getAllLegalMoves(white);

      if (legal.size() == 0) {
        return analysisLegal.isKingInCheck(white) ? -MATE : 0;
      }

      if (legal.size() == 1) {
        if (chain > 6) return analysisEngine.evalSide(white);

        Position snap = capture(analysisStatus.fieldObject, analysisLegal, white, 0);
        analysisEngine.applySearchMove(legal.get(0)[0], legal.get(0)[1]);
        int child = scorePosition(!white, depth, timeMs, gameID, chain + 1);
        loadPosition(snap);

        return -child;
      }

      analysisEngine.positionHistory.clear();
      analysisEngine.timeLimitMs = timeMs;
      analysisEngine.findBestMove(white, depth, gameID);

      return analysisEngine.lastScore;
    }

    boolean isOnlyMove(Position prev, RatedMove move, int gen) {
      loadPosition(prev);

      boolean white = prev.whiteToMove;
      ArrayList<int[]> legal = analysisLegal.getAllLegalMoves(white);

      if (legal.size() < 2) return false;

      float played = -1;
      float bestOther = -1;

      for (int[] m : legal) {
        if (gen != generation) return false;

        analysisEngine.applySearchMove(m[0], m[1]);
        int childScore = scorePosition(!white, scanDepth, scanTimeMs, prev.gameID, 0);
        loadPosition(prev);

        float wc = winChance(-childScore);

        if (m[0] == move.from && m[1] == move.toPOS) {
          played = wc;
        } else {
          bestOther = max(bestOther, wc);
        }
      }

      return played >= 0 && played - bestOther >= onlyMoveMargin;
    }

    boolean isSacrifice(RatedMove move) {
      int[][] board = analysisStatus.fieldObject;
      int row = move.toPOS / 8;
      int col = move.toPOS % 8;

      int piece = board[row][col];
      int value = pieceValue(piece);

      if (value < 300 || value >= 20000) return false;

      int attacker = lowestAttackerValue(row, col, !move.moverWhite);
      if (attacker >= 1000000) return false;

      int defender = lowestAttackerValue(row, col, move.moverWhite);
      int net = pieceValue(move.captured) + (defender < 1000000 ? attacker : 0) - value;

      return net <= -200;
    }

    int lowestAttackerValue(int row, int col, boolean byWhite) {
      int[][] board = analysisStatus.fieldObject;
      int best = 1000000;

      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          int p = board[r][c];

          if (p == 0 || (p <= 6) != byWhite) continue;
          if (r == row && c == col) continue;

          if (analysisLegal.pieceAttacksSquare(r, c, row, col, p)) {
            best = min(best, pieceValue(p));
          }
        }
      }

      return best;
    }

    void loadPosition(Position p) {
      for (int row = 0; row < 8; row++) {
        System.arraycopy(p.board[row], 0, analysisStatus.fieldObject[row], 0, 8);
      }

      analysisLegal.enPassantTarget = p.enPassantTarget;
      analysisLegal.enPassantPawnField = p.enPassantPawnField;
      analysisLegal.whiteKingSide = p.whiteKingSide;
      analysisLegal.whiteQueenSide = p.whiteQueenSide;
      analysisLegal.blackKingSide = p.blackKingSide;
      analysisLegal.blackQueenSide = p.blackQueenSide;
    }
  }
}
