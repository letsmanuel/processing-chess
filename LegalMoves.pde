import java.util.ArrayList;

class LegalMoves {

  GameStatus gameStatus;

  int enPassantTarget = -1;
  int enPassantPawnField = -1;

  boolean whiteKingSide = true;
  boolean whiteQueenSide = true;
  boolean blackKingSide = true;
  boolean blackQueenSide = true;

  LegalMoves(GameStatus gameStatus) {
    this.gameStatus = gameStatus;
  }

  int[] getLegalMoves(int fieldID) {
    if (!isValidField(fieldID)) return new int[0];

    int row = fieldID / 8;
    int col = fieldID % 8;
    int piece = gameStatus.fieldObject[row][col];

    if (piece == 0) return new int[0];

    ArrayList<Integer> candidates = new ArrayList<Integer>();

    if (piece == 1 || piece == 7) {
      getPawnMoves(row, col, piece, candidates);
    } else if (piece == 2 || piece == 8) {
      getSlidingMoves(row, col, piece, candidates, new int[][] {
        {-1, 0}, {1, 0}, {0, -1}, {0, 1}
        });
    } else if (piece == 4 || piece == 10) {
      getSlidingMoves(row, col, piece, candidates, new int[][] {
        {-1, -1}, {-1, 1}, {1, -1}, {1, 1}
        });
    } else if (piece == 5 || piece == 11) {
      getSlidingMoves(row, col, piece, candidates, new int[][] {
        {-1, 0}, {1, 0}, {0, -1}, {0, 1},
        {-1, -1}, {-1, 1}, {1, -1}, {1, 1}
        });
    } else if (piece == 3 || piece == 9) {
      getKnightMoves(row, col, piece, candidates);
    } else if (piece == 6 || piece == 12) {
      getKingMoves(row, col, piece, candidates);
    }

    ArrayList<Integer> legal = new ArrayList<Integer>();

    for (int target : candidates) {
      if (!wouldLeaveKingInCheck(fieldID, target, piece)) {
        legal.add(target);
      }
    }

    int[] result = new int[legal.size()];

    for (int i = 0; i < legal.size(); i++) {
      result[i] = legal.get(i);
    }

    return result;
  }

  void getPawnMoves(int row, int col, int piece,
    ArrayList<Integer> moves) {

    int[][] board = gameStatus.fieldObject;
    int direction = piece == 1 ? -1 : 1;
    int startRow = piece == 1 ? 6 : 1;
    int nextRow = row + direction;

    if (isInsideBoard(nextRow, col) && board[nextRow][col] == 0) {
      moves.add(toFieldID(nextRow, col));

      int doubleRow = row + direction * 2;

      if (row == startRow && board[doubleRow][col] == 0) {
        moves.add(toFieldID(doubleRow, col));
      }
    }

    for (int dc = -1; dc <= 1; dc += 2) {
      int captureRow = row + direction;
      int captureCol = col + dc;

      if (!isInsideBoard(captureRow, captureCol)) continue;

      int target = board[captureRow][captureCol];

      if (isOpponent(piece, target) && !isKingPiece(target)) {
        moves.add(toFieldID(captureRow, captureCol));
      }
    }

    if (enPassantTarget < 0 || enPassantTarget >= 64) return;
    if (enPassantPawnField < 0 || enPassantPawnField >= 64) return;

    int targetRow = enPassantTarget / 8;
    int targetCol = enPassantTarget % 8;

    if (targetRow != row + direction) return;
    if (Math.abs(targetCol - col) != 1) return;
    if (board[targetRow][targetCol] != 0) return;

    int pawnRow = enPassantPawnField / 8;
    int pawnCol = enPassantPawnField % 8;
    int opposingPawn = piece == 1 ? 7 : 1;

    if (pawnRow == row && pawnCol == targetCol
      && board[pawnRow][pawnCol] == opposingPawn) {
      moves.add(enPassantTarget);
    }
  }

  void getKnightMoves(int row, int col, int piece,
    ArrayList<Integer> moves) {

    int[][] offsets = {
      {-2, -1}, {-2, 1},
      {-1, -2}, {-1, 2},
      {1, -2}, {1, 2},
      {2, -1}, {2, 1}
    };

    for (int[] offset : offsets) {
      int r = row + offset[0];
      int c = col + offset[1];

      if (canMoveTo(r, c, piece)) {
        moves.add(toFieldID(r, c));
      }
    }
  }

  void getKingMoves(int row, int col, int piece,
    ArrayList<Integer> moves) {

    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;

        int r = row + dr;
        int c = col + dc;

        if (canMoveTo(r, c, piece)) {
          moves.add(toFieldID(r, c));
        }
      }
    }

    if (piece != 6 && piece != 12) return;

    boolean white = piece == 6;
    int homeRow = white ? 7 : 0;

    if (row != homeRow || col != 4) return;
    if (isKingInCheck(white)) return;

    boolean kingSide = white ? whiteKingSide : blackKingSide;
    boolean queenSide = white ? whiteQueenSide : blackQueenSide;
    int rook = white ? 2 : 8;

    if (kingSide
      && gameStatus.fieldObject[homeRow][7] == rook
      && gameStatus.fieldObject[homeRow][5] == 0
      && gameStatus.fieldObject[homeRow][6] == 0
      && !isSquareAttacked(homeRow, 5, !white)
      && !isSquareAttacked(homeRow, 6, !white)) {
      moves.add(toFieldID(homeRow, 6));
    }

    if (queenSide
      && gameStatus.fieldObject[homeRow][0] == rook
      && gameStatus.fieldObject[homeRow][1] == 0
      && gameStatus.fieldObject[homeRow][2] == 0
      && gameStatus.fieldObject[homeRow][3] == 0
      && !isSquareAttacked(homeRow, 3, !white)
      && !isSquareAttacked(homeRow, 2, !white)) {
      moves.add(toFieldID(homeRow, 2));
    }
  }

  void getSlidingMoves(int row, int col, int piece,
    ArrayList<Integer> moves, int[][] directions) {

    int[][] board = gameStatus.fieldObject;

    for (int[] direction : directions) {
      int r = row + direction[0];
      int c = col + direction[1];

      while (isInsideBoard(r, c)) {
        int target = board[r][c];

        if (target == 0) {
          moves.add(toFieldID(r, c));
        } else {
          if (isOpponent(piece, target) && !isKingPiece(target)) {
            moves.add(toFieldID(r, c));
          }

          break;
        }

        r += direction[0];
        c += direction[1];
      }
    }
  }

  boolean canMoveTo(int row, int col, int piece) {
    if (!isInsideBoard(row, col)) return false;

    int target = gameStatus.fieldObject[row][col];

    if (target == 0) return true;

    return isOpponent(piece, target) && !isKingPiece(target);
  }

  boolean wouldLeaveKingInCheck(int from, int toPOS, int piece) {
    int[][] board = gameStatus.fieldObject;

    int fromRow = from / 8;
    int fromCol = from % 8;
    int toRow = toPOS / 8;
    int toCol = toPOS % 8;

    int capturedPiece = board[toRow][toCol];
    int capturedRow = toRow;
    int capturedCol = toCol;

    boolean enPassant =
      (piece == 1 || piece == 7)
      && toPOS == enPassantTarget
      && capturedPiece == 0
      && fromCol != toCol;

    if (enPassant) {
      capturedRow = fromRow;
      capturedCol = toCol;
      capturedPiece = board[capturedRow][capturedCol];
    }

    boolean castle =
      (piece == 6 || piece == 12)
      && fromRow == toRow
      && Math.abs(toCol - fromCol) == 2;

    int rookFrom = -1;
    int rookTo = -1;
    int rookPiece = 0;

    if (castle) {
      rookFrom = fromRow * 8 + (toCol > fromCol ? 7 : 0);
      rookTo = fromRow * 8 + (toCol > fromCol ? 5 : 3);
      rookPiece = board[rookFrom / 8][rookFrom % 8];
    }

    board[fromRow][fromCol] = 0;

    if (enPassant) {
      board[capturedRow][capturedCol] = 0;
    }

    board[toRow][toCol] = piece;

    if (castle) {
      board[rookFrom / 8][rookFrom % 8] = 0;
      board[rookTo / 8][rookTo % 8] = rookPiece;
    }

    boolean inCheck = isKingInCheck(isWhitePiece(piece));

    board[fromRow][fromCol] = piece;
    board[toRow][toCol] = enPassant ? 0 : capturedPiece;

    if (enPassant) {
      board[capturedRow][capturedCol] = capturedPiece;
    }

    if (castle) {
      board[rookFrom / 8][rookFrom % 8] = rookPiece;
      board[rookTo / 8][rookTo % 8] = 0;
    }

    return inCheck;
  }

  boolean isKingInCheck(boolean white) {
    int kingPiece = white ? 6 : 12;
    int kingRow = -1;
    int kingCol = -1;

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        if (gameStatus.fieldObject[row][col] == kingPiece) {
          kingRow = row;
          kingCol = col;
          break;
        }
      }

      if (kingRow != -1) break;
    }

    if (kingRow == -1) return false;

    return isSquareAttacked(kingRow, kingCol, !white);
  }

  boolean isSquareAttacked(int row, int col, boolean byWhite) {
    int[][] board = gameStatus.fieldObject;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        int piece = board[r][c];

        if (piece == 0 || isWhitePiece(piece) != byWhite) continue;

        if (pieceAttacksSquare(r, c, row, col, piece)) {
          return true;
        }
      }
    }

    return false;
  }

  boolean pieceAttacksSquare(int row, int col,
    int targetRow, int targetCol, int piece) {

    int dr = targetRow - row;
    int dc = targetCol - col;
    int absDr = Math.abs(dr);
    int absDc = Math.abs(dc);

    if (piece == 1) return dr == -1 && absDc == 1;
    if (piece == 7) return dr == 1 && absDc == 1;

    if (piece == 3 || piece == 9) {
      return (absDr == 2 && absDc == 1)
        || (absDr == 1 && absDc == 2);
    }

    if (piece == 6 || piece == 12) {
      return absDr <= 1 && absDc <= 1
        && absDr + absDc > 0;
    }

    boolean rookLike =
      piece == 2 || piece == 8 || piece == 5 || piece == 11;

    boolean bishopLike =
      piece == 4 || piece == 10 || piece == 5 || piece == 11;

    if (rookLike && (dr == 0 || dc == 0)
      && (dr != 0 || dc != 0)) {
      return pathIsClear(row, col, targetRow, targetCol);
    }

    if (bishopLike && absDr == absDc && absDr > 0) {
      return pathIsClear(row, col, targetRow, targetCol);
    }

    return false;
  }

  boolean pathIsClear(int row, int col,
    int targetRow, int targetCol) {

    int dr = Integer.compare(targetRow, row);
    int dc = Integer.compare(targetCol, col);
    int r = row + dr;
    int c = col + dc;
    int[][] board = gameStatus.fieldObject;

    while (r != targetRow || c != targetCol) {
      if (board[r][c] != 0) return false;

      r += dr;
      c += dc;
    }

    return true;
  }

  boolean promotionPending = false;
  int promotionField = -1;
  int promotionPawn = 0;


  boolean makeMove(int from, int toPOS, boolean showPromotionGUI) {
    if (!isValidField(from) || !isValidField(toPOS)) return false;
    if (promotionPending) return false;

    int fromRow = from / 8;
    int fromCol = from % 8;
    int toRow = toPOS / 8;
    int toCol = toPOS % 8;
    boolean isHalfMove = true;


    int[][] board = gameStatus.fieldObject;
    int piece = board[fromRow][fromCol];

    if (piece == 0) return false;
    if (piece == 1 || piece == 7) isHalfMove = false;
    int[] legalMoves = getLegalMoves(from);
    boolean found = false;

    for (int target : legalMoves) {
      if (target == toPOS) {
        found = true;
        break;
      }
    }

    if (!found) {
      gameStatus.soundQueue = append(gameStatus.soundQueue, "illegal");
      return false;
    }

    gameStatus.lastMoveFrom = from;
    gameStatus.lastMoveTo = toPOS;
    gameStatus.firstMoveDone = true;

    lastMoveListRenderer.pushNewMove(from, toPOS);

    boolean promotes =
      (piece == 1 && toRow == 0) ||
      (piece == 7 && toRow == 7);

    int capturedPiece = board[toRow][toCol];

    if (capturedPiece > 0) {
      gameStatus.soundQueue = append(gameStatus.soundQueue, "capture");
      isHalfMove = false;
    }

    int capturedSquare = toPOS;

    boolean enPassant =
      (piece == 1 || piece == 7)
      && toPOS == enPassantTarget
      && capturedPiece == 0
      && fromCol != toCol;

    if (enPassant) {
      capturedSquare = enPassantPawnField;
      capturedPiece = board[capturedSquare / 8][capturedSquare % 8];
    }

    updateCastlingRights(from, piece);
    updateCastlingRights(capturedSquare, capturedPiece);

    boolean castle =
      (piece == 6 || piece == 12)
      && Math.abs(toCol - fromCol) == 2;

    enPassantTarget = -1;
    enPassantPawnField = -1;

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

    if ((piece == 1 || piece == 7)
      && Math.abs(toRow - fromRow) == 2) {
      enPassantTarget = (from + toPOS) / 2;
      enPassantPawnField = toPOS;
    }
    
    //saveManager.save("recentData","lastMove",from+"\t"+toPOS,true);

    if (promotes) {
      if (showPromotionGUI) {
        promotionPending = true;
        promotionField = toPOS;
        promotionPawn = piece;
        gameStatus.promotionChoice = 0;
        overlayRenderer.startPromotion(piece == 1);
      } else {
        board[toRow][toCol] = piece == 1 ? 5 : 11;
        gameStatus.soundQueue = append(gameStatus.soundQueue, "promote");
      }
    }

    moveRating.moveMade(from, toPOS, piece > 6);
    if (isHalfMove) gameStatus.halfMoveCounter++;
    if (!isHalfMove) gameStatus.halfMoveCounter = 0;
    
    return true;
  }

  boolean completePromotion() {
    if (!promotionPending) return false;
    if (gameStatus.promotionChoice == 0) return false;

    int choice = gameStatus.promotionChoice;

    boolean validChoice =
      promotionPawn == 1
      ? choice == 5 || choice == 2 || choice == 3 || choice == 4
      : choice == 11 || choice == 8 || choice == 9 || choice == 10;

    if (!validChoice) {
      gameStatus.promotionChoice = 0;
      return false;
    }

    int row = promotionField / 8;
    int col = promotionField % 8;

    gameStatus.fieldObject[row][col] = choice;

    gameStatus.promotionPending = false;
    promotionPending = false;
    promotionField = -1;
    promotionPawn = 0;
    gameStatus.promotionChoice = 0;

    gameStatus.soundQueue = append(gameStatus.soundQueue, "promote");
    return true;
  }

  void updateCastlingRights(int fieldID, int piece) {
    if (piece == 6) {
      whiteKingSide = false;
      whiteQueenSide = false;
    } else if (piece == 12) {
      blackKingSide = false;
      blackQueenSide = false;
    }

    if (fieldID == 63 && piece == 2) whiteKingSide = false;
    if (fieldID == 56 && piece == 2) whiteQueenSide = false;
    if (fieldID == 7 && piece == 8) blackKingSide = false;
    if (fieldID == 0 && piece == 8) blackQueenSide = false;
  }

  int getGameResult(boolean whiteToMove) {
    ArrayList<int[]> moves = getAllLegalMoves(whiteToMove);

    if (moves.size() > 0) return 0;

    if (isKingInCheck(whiteToMove)) {
      return whiteToMove ? -1 : 1;
    }

    return 2;
  }

  ArrayList<int[]> getAllLegalMoves(boolean white) {
    ArrayList<int[]> allMoves = new ArrayList<int[]>();

    for (int fieldID = 0; fieldID < 64; fieldID++) {
      int row = fieldID / 8;
      int col = fieldID % 8;
      int piece = gameStatus.fieldObject[row][col];

      if (piece == 0 || isWhitePiece(piece) != white) continue;

      int[] moves = getLegalMoves(fieldID);

      for (int target : moves) {
        allMoves.add(new int[] {fieldID, target});
      }
    }

    return allMoves;
  }

  int[][] getAllLegalMovesArray(boolean white, boolean printLegalMoves) {
    ArrayList<int[]> moves = getAllLegalMoves(white);

    if (printLegalMoves) {
      for (int[] move : moves) {
        println("From " + move[0] + " toPOS " + move[1]);
      }
    }

    return moves.toArray(new int[moves.size()][]);
  }

  boolean isOpponent(int piece, int target) {
    return target != 0
      && isWhitePiece(piece) != isWhitePiece(target);
  }

  boolean isWhitePiece(int piece) {
    return piece >= 1 && piece <= 6;
  }

  boolean isKingPiece(int piece) {
    return piece == 6 || piece == 12;
  }

  boolean isInsideBoard(int row, int col) {
    return row >= 0 && row < 8
      && col >= 0 && col < 8;
  }

  boolean isValidField(int fieldID) {
    return fieldID >= 0 && fieldID < 64;
  }

  int toFieldID(int row, int col) {
    return row * 8 + col;
  }
}
