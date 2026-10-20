import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Random;

class ChessEngine {

  GameStatus gameStatus;
  LegalMoves legalMoves;
  PositionEvaluator positionEvaluator;

  HashMap<Long, Integer> positionHistory = new HashMap<Long, Integer>();
  HashMap<Long, Integer> searchHistory = new HashMap<Long, Integer>();

  int maxDepth = 50;
  int timeLimitMs = 2000;

  long nodesSearched = 0;
  int lastDepthReached = 0;
  int lastScore = 0;

  static final int MATE_SCORE = 100000;
  static final int INFINITY = 1000000;
  static final int MATE_THRESHOLD = MATE_SCORE - 1000;
  static final int MAX_PLY = 128;

  static final int TT_BITS = 19;
  static final int TT_SIZE = 1 << TT_BITS;
  static final int TT_EXACT = 0;
  static final int TT_LOWER = 1;
  static final int TT_UPPER = 2;

  long[] ttKey = new long[TT_SIZE];
  int[] ttScore = new int[TT_SIZE];
  int[] ttMove = new int[TT_SIZE];
  byte[] ttDepth = new byte[TT_SIZE];
  byte[] ttFlag = new byte[TT_SIZE];

  int[][] killers = new int[MAX_PLY][2];
  int[] history = new int[64 * 64];

  long[][] zPiece = new long[13][64];
  long zSide;
  long[] zCastle = new long[4];
  long[] zEp = new long[64];

  BoardSnapshot[] snapshots = new BoardSnapshot[MAX_PLY];

  long deadline = Long.MAX_VALUE;
  boolean stopped = false;

  ChessEngine(
    GameStatus gameStatus,
    LegalMoves legalMoves,
    PositionEvaluator positionEvaluator
    ) {
    this.gameStatus = gameStatus;
    this.legalMoves = legalMoves;
    this.positionEvaluator = positionEvaluator;

    Random rnd = new Random(20240607L);
    for (int p = 0; p < 13; p++) {
      for (int s = 0; s < 64; s++) {
        zPiece[p][s] = rnd.nextLong();
      }
    }
    zSide = rnd.nextLong();
    for (int i = 0; i < 4; i++) zCastle[i] = rnd.nextLong();
    for (int i = 0; i < 64; i++) zEp[i] = rnd.nextLong();

    for (int i = 0; i < MAX_PLY; i++) {
      snapshots[i] = new BoardSnapshot();
    }
  }

  int[] findBestMove(boolean whiteToMove) {
    return findBestMove(whiteToMove, maxDepth, gameStatus.gameID);
  }

  int[] findBestMove(boolean whiteToMove, int depth, int gameID) {
    if (depth < 1) depth = 1;
    if (depth > MAX_PLY / 2) depth = MAX_PLY / 2;
    int[] errorList = {};
    if (gameID > gameStatus.gameID) return errorList;

    nodesSearched = 0;
    stopped = false;
    lastDepthReached = 0;
    lastScore = 0;
    searchHistory.clear();
    Arrays.fill(ttKey, 0L);
    Arrays.fill(history, 0);
    for (int i = 0; i < MAX_PLY; i++) {
      killers[i][0] = 0;
      killers[i][1] = 0;
    }

    deadline = timeLimitMs > 0 ? System.currentTimeMillis() + timeLimitMs : Long.MAX_VALUE;

    long rootHash = computeHash(whiteToMove);

    if (!positionHistory.containsKey(rootHash)) {
      positionHistory.put(rootHash, 1);
    }

    ArrayList<int[]> legal = legalMoves.getAllLegalMoves(whiteToMove);

    if (legal.size() == 0) return null;
    if (legal.size() == 1) {
      return new int[] {legal.get(0)[0], legal.get(0)[1]};
    }

    ArrayList<int[]> rootMoves = orderMoves(legal, 0, 0);

    searchHistory.put(rootHash, 1);

    ArrayList<int[]> bestMoves = new ArrayList<int[]>();
    bestMoves.add(new int[] {rootMoves.get(0)[0], rootMoves.get(0)[1]});

    for (int d = 1; d <= depth; d++) {
      int bestScore = -INFINITY;
      ArrayList<int[]> iterBest = new ArrayList<int[]>();

      for (int i = 0; i < rootMoves.size(); i++) {
        int[] m = rootMoves.get(i);

        BoardSnapshot snap = snapshots[0];
        snap.copyFrom(gameStatus.fieldObject, legalMoves);

        applySearchMove(m[0], m[1]);

        int a = iterBest.size() > 0 ? bestScore - 1 : -INFINITY;

        int score = -negamax(d - 1, -INFINITY, -a, !whiteToMove, 1);

        restorePosition(snap);

        if (stopped) break;

        m[2] = score;

        if (iterBest.size() == 0 || score > bestScore) {
          bestScore = score;
          iterBest.clear();
          iterBest.add(new int[] {m[0], m[1]});
        } else if (score == bestScore) {
          iterBest.add(new int[] {m[0], m[1]});
        }
      }

      if (stopped) break;

      bestMoves = iterBest;
      lastDepthReached = d;
      lastScore = bestScore;

      rootMoves.sort((x, y) -> Integer.compare(y[2], x[2]));

      if (Math.abs(bestScore) > MATE_THRESHOLD) break;
    }

    searchHistory.clear();

    return bestMoves.get((int) random(bestMoves.size()));
  }

  int negamax(int depth, int alpha, int beta, boolean white, int ply) {
    nodesSearched++;
    if (timeUp()) return 0;
    if (ply >= MAX_PLY - 1) return evalSide(white);

    long hash = computeHash(white);

    int rep = searchHistory.containsKey(hash) ? searchHistory.get(hash) : 0;
    int game = positionHistory.containsKey(hash) ? positionHistory.get(hash) : 0;
    if (rep >= 1 || game >= 1) return 0;

    boolean inCheck = legalMoves.isKingInCheck(white);
    if (inCheck && ply < 40) depth++;

    if (depth <= 0) return quiesce(alpha, beta, white, ply);

    int origAlpha = alpha;

    int idx = (int) (hash & (TT_SIZE - 1));
    int ttMv = 0;
    if (ttKey[idx] == hash) {
      ttMv = ttMove[idx];
      if (ttDepth[idx] >= depth) {
        int s = ttScore[idx];
        if (s > MATE_THRESHOLD) s -= ply;
        else if (s < -MATE_THRESHOLD) s += ply;

        int f = ttFlag[idx];
        if (f == TT_EXACT) return s;
        if (f == TT_LOWER && s >= beta) return s;
        if (f == TT_UPPER && s <= alpha) return s;
      }
    }

    ArrayList<int[]> raw = legalMoves.getAllLegalMoves(white);

    if (raw.size() == 0) {
      return inCheck ? -MATE_SCORE + ply : 0;
    }

    if (insufficientMaterial()) return 0;

    ArrayList<int[]> moves = orderMoves(raw, ply, ttMv);

    searchHistory.put(hash, 1);

    int[][] board = gameStatus.fieldObject;
    int best = -INFINITY;
    int bestMove = 0;

    for (int i = 0; i < moves.size(); i++) {
      int[] m = moves.get(i);
      int from = m[0];
      int toPOS = m[1];
      int code = from * 64 + toPOS;

      int piece = board[from / 8][from % 8];
      int victim = board[toPOS / 8][toPOS % 8];
      boolean capture = victim != 0 || isEnPassant(piece, from, toPOS, victim);
      boolean quiet = !capture && !isPromotion(piece, toPOS);

      BoardSnapshot snap = snapshots[ply];
      snap.copyFrom(board, legalMoves);

      applySearchMove(from, toPOS);

      int score;

      if (i == 0) {
        score = -negamax(depth - 1, -beta, -alpha, !white, ply + 1);
      } else {
        int reduction = (depth >= 3 && i >= 4 && quiet && !inCheck) ? 1 : 0;

        score = -negamax(depth - 1 - reduction, -alpha - 1, -alpha, !white, ply + 1);

        if (score > alpha && reduction > 0) {
          score = -negamax(depth - 1, -alpha - 1, -alpha, !white, ply + 1);
        }
        if (score > alpha && score < beta) {
          score = -negamax(depth - 1, -beta, -alpha, !white, ply + 1);
        }
      }

      restorePosition(snap);

      if (stopped) {
        searchHistory.remove(hash);
        return 0;
      }

      if (score > best) {
        best = score;
        bestMove = code;
      }

      if (score > alpha) alpha = score;

      if (alpha >= beta) {
        if (quiet) {
          if (killers[ply][0] != code) {
            killers[ply][1] = killers[ply][0];
            killers[ply][0] = code;
          }
          history[code] += depth * depth;
          if (history[code] > 60000) history[code] = 60000;
        }
        break;
      }
    }

    searchHistory.remove(hash);

    int flag;
    if (best <= origAlpha) flag = TT_UPPER;
    else if (best >= beta) flag = TT_LOWER;
    else flag = TT_EXACT;

    int store = best;
    if (store > MATE_THRESHOLD) store += ply;
    else if (store < -MATE_THRESHOLD) store -= ply;

    ttKey[idx] = hash;
    ttScore[idx] = store;
    ttMove[idx] = bestMove;
    ttDepth[idx] = (byte) Math.min(depth, 127);
    ttFlag[idx] = (byte) flag;

    return best;
  }

  int quiesce(int alpha, int beta, boolean white, int ply) {
    nodesSearched++;
    if (timeUp()) return 0;

    int stand = evalSide(white);

    if (ply >= MAX_PLY - 1) return stand;
    if (stand >= beta) return stand;
    if (stand > alpha) alpha = stand;

    ArrayList<int[]> raw = legalMoves.getAllLegalMoves(white);

    if (raw.size() == 0) {
      return legalMoves.isKingInCheck(white) ? -MATE_SCORE + ply : 0;
    }

    int[][] board = gameStatus.fieldObject;
    ArrayList<int[]> tactical = new ArrayList<int[]>();

    for (int[] m : raw) {
      int piece = board[m[0] / 8][m[0] % 8];
      int victim = board[m[1] / 8][m[1] % 8];

      if (victim != 0 || isPromotion(piece, m[1]) || isEnPassant(piece, m[0], m[1], victim)) {
        tactical.add(m);
      }
    }

    ArrayList<int[]> moves = orderMoves(tactical, ply, 0);

    int best = stand;

    for (int i = 0; i < moves.size(); i++) {
      int[] m = moves.get(i);

      BoardSnapshot snap = snapshots[ply];
      snap.copyFrom(board, legalMoves);

      applySearchMove(m[0], m[1]);

      int score = -quiesce(-beta, -alpha, !white, ply + 1);

      restorePosition(snap);

      if (stopped) return 0;

      if (score > best) best = score;
      if (score > alpha) alpha = score;
      if (alpha >= beta) break;
    }

    return best;
  }

  boolean timeUp() {
    if (!stopped
      && (nodesSearched & 1023) == 0
      && System.currentTimeMillis() >= deadline) {
      stopped = true;
    }
    return stopped;
  }

  int evalSide(boolean white) {
    int eval = positionEvaluator.getCurrentEval(gameStatus.fieldObject);
    return white ? eval : -eval;
  }

  int pieceType(int p) {
    return (p - 1) % 6;
  }

  int orderValue(int p) {
    switch (pieceType(p)) {
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
      return 2000;
    }
  }

  boolean isPromotion(int piece, int toPOS) {
    return (piece == 1 && toPOS / 8 == 0) || (piece == 7 && toPOS / 8 == 7);
  }

  boolean isEnPassant(int piece, int from, int toPOS, int victim) {
    return (piece == 1 || piece == 7) && toPOS == legalMoves.enPassantTarget && victim == 0 && (from % 8) != (toPOS % 8);
  }

  ArrayList<int[]> orderMoves(ArrayList<int[]> moves, int ply, int ttMv) {
    int[][] board = gameStatus.fieldObject;
    ArrayList<int[]> out = new ArrayList<int[]>(moves.size());

    for (int[] m : moves) {
      int from = m[0];
      int toPOS = m[1];
      int code = from * 64 + toPOS;

      int piece = board[from / 8][from % 8];
      int victim = board[toPOS / 8][toPOS % 8];

      boolean ep = isEnPassant(piece, from, toPOS, victim);
      if (ep) victim = (piece == 1) ? 7 : 1;

      boolean promo = isPromotion(piece, toPOS);

      int s;

      if (ttMv != 0 && code == ttMv) {
        s = 1000000;
      } else if (victim != 0) {
        s = 100000 + 10 * orderValue(victim) - orderValue(piece);
        if (promo) s += 5000;
      } else if (promo) {
        s = 90000;
      } else if (ply < MAX_PLY && killers[ply][0] == code) {
        s = 80000;
      } else if (ply < MAX_PLY && killers[ply][1] == code) {
        s = 79000;
      } else {
        s = history[code];
      }

      out.add(new int[] {from, toPOS, s});
    }

    out.sort((x, y) -> Integer.compare(y[2], x[2]));
    return out;
  }

  boolean insufficientMaterial() {
    int[][] board = gameStatus.fieldObject;
    int count = 0;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        int p = board[r][c];
        if (p == 0) continue;

        int t = pieceType(p);
        if (t == 5) continue;
        if (t == 0 || t == 1 || t == 4) return false;
        count++;
      }
    }

    return count <= 1;
  }

  long computeHash(boolean whiteToMove) {
    long h = 0L;
    int[][] board = gameStatus.fieldObject;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        int p = board[r][c];
        if (p != 0) h ^= zPiece[p][r * 8 + c];
      }
    }

    if (!whiteToMove) h ^= zSide;
    if (legalMoves.whiteKingSide) h ^= zCastle[0];
    if (legalMoves.whiteQueenSide) h ^= zCastle[1];
    if (legalMoves.blackKingSide) h ^= zCastle[2];
    if (legalMoves.blackQueenSide) h ^= zCastle[3];

    int ep = legalMoves.enPassantTarget;
    if (ep >= 0 && ep < 64) h ^= zEp[ep];

    return h;
  }

  void applySearchMove(int from, int toPOS) {
    int fromRow = from / 8;
    int fromCol = from % 8;
    int toRow = toPOS / 8;
    int toCol = toPOS % 8;

    int[][] board = gameStatus.fieldObject;
    int piece = board[fromRow][fromCol];

    if (piece == 0) return;

    int capturedSquare = toPOS;
    int capturedPiece = board[toRow][toCol];

    boolean enPassant =
      (piece == 1 || piece == 7)
      && toPOS == legalMoves.enPassantTarget
      && capturedPiece == 0
      && fromCol != toCol;

    if (enPassant) {
      capturedSquare = legalMoves.enPassantPawnField;
      capturedPiece = board[capturedSquare / 8][capturedSquare % 8];
    }

    legalMoves.updateCastlingRights(from, piece);
    legalMoves.updateCastlingRights(capturedSquare, capturedPiece);

    boolean castle = (piece == 6 || piece == 12) && Math.abs(toCol - fromCol) == 2;

    legalMoves.enPassantTarget = -1;
    legalMoves.enPassantPawnField = -1;

    board[fromRow][fromCol] = 0;

    if (enPassant) {
      board[capturedSquare / 8][capturedSquare % 8] = 0;
    }

    board[toRow][toCol] = piece;

    if (castle) {
      int rookFromCol = toCol > fromCol ? 7 : 0;
      int rookToCol = toCol > fromCol ? 5 : 3;

      board[fromRow][rookToCol] = board[fromRow][rookFromCol];
      board[fromRow][rookFromCol] = 0;
    }

    if ((piece == 1 || piece == 7) && Math.abs(toRow - fromRow) == 2) {
      legalMoves.enPassantTarget = (from + toPOS) / 2;
      legalMoves.enPassantPawnField = toPOS;
    }

    if (piece == 1 && toRow == 0) {
      board[toRow][toCol] = 5;
    } else if (piece == 7 && toRow == 7) {
      board[toRow][toCol] = 11;
    }
  }

  boolean updateMoves(int from, int toPOS) {
    if (from < 0 || from >= 64 || toPOS < 0 || toPOS >= 64) {
      return false;
    }

    boolean moved = legalMoves.makeMove(from, toPOS, false);

    return moved;
  }

  void recordPosition(boolean whiteToMove) {
    long key = computeHash(whiteToMove);

    int count = positionHistory.containsKey(key)
      ? positionHistory.get(key)
      : 0;

    positionHistory.put(key, count + 1);
  }

  void resetPositionHistory(boolean whiteToMove) {
    positionHistory.clear();
    searchHistory.clear();
    recordPosition(whiteToMove);
  }

  String getPositionKey(boolean whiteToMove) {
    StringBuilder key = new StringBuilder();

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        key.append(gameStatus.fieldObject[row][col]);
        key.append(',');
      }
    }

    key.append(whiteToMove ? 'w' : 'b');

    key.append(legalMoves.whiteKingSide ? 'K' : '-');
    key.append(legalMoves.whiteQueenSide ? 'Q' : '-');
    key.append(legalMoves.blackKingSide ? 'k' : '-');
    key.append(legalMoves.blackQueenSide ? 'q' : '-');

    key.append(':').append(legalMoves.enPassantTarget);

    return key.toString();
  }

  BoardSnapshot savePosition() {
    return new BoardSnapshot(gameStatus.fieldObject, legalMoves);
  }

  void restorePosition(BoardSnapshot snapshot) {
    for (int row = 0; row < 8; row++) {
      System.arraycopy(
        snapshot.board[row],
        0,
        gameStatus.fieldObject[row],
        0,
        8
        );
    }

    legalMoves.enPassantTarget = snapshot.enPassantTarget;
    legalMoves.enPassantPawnField = snapshot.enPassantPawnField;

    legalMoves.whiteKingSide = snapshot.whiteKingSide;
    legalMoves.whiteQueenSide = snapshot.whiteQueenSide;
    legalMoves.blackKingSide = snapshot.blackKingSide;
    legalMoves.blackQueenSide = snapshot.blackQueenSide;
  }

  class BoardSnapshot {
    int[][] board = new int[8][8];

    int enPassantTarget;
    int enPassantPawnField;

    boolean whiteKingSide;
    boolean whiteQueenSide;
    boolean blackKingSide;
    boolean blackQueenSide;

    BoardSnapshot() {
    }

    BoardSnapshot(int[][] source, LegalMoves legal) {
      copyFrom(source, legal);
    }

    void copyFrom(int[][] source, LegalMoves legal) {
      for (int row = 0; row < 8; row++) {
        System.arraycopy(source[row], 0, board[row], 0, 8);
      }

      enPassantTarget = legal.enPassantTarget;
      enPassantPawnField = legal.enPassantPawnField;

      whiteKingSide = legal.whiteKingSide;
      whiteQueenSide = legal.whiteQueenSide;
      blackKingSide = legal.blackKingSide;
      blackQueenSide = legal.blackQueenSide;
    }
  }
}
