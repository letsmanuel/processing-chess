class PositionEvaluator {

  final int[] PAWN_TABLE = {
    0, 0, 0, 0, 0, 0, 0, 0,
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
    5, 5, 10, 25, 25, 10, 5, 5,
    0, 0, 0, 20, 20, 0, 0, 0,
    5, -5, -10, 0, 0, -10, -5, 5,
    5, 10, 10, -20, -20, 10, 10, 5,
    0, 0, 0, 0, 0, 0, 0, 0
  };

  final int[] KNIGHT_TABLE = {
    -50, -40, -30, -30, -30, -30, -40, -50,
    -40, -20, 0, 0, 0, 0, -20, -40,
    -30, 0, 10, 15, 15, 10, 0, -30,
    -30, 5, 15, 20, 20, 15, 5, -30,
    -30, 0, 15, 20, 20, 15, 0, -30,
    -30, 5, 10, 15, 15, 10, 5, -30,
    -40, -20, 0, 5, 5, 0, -20, -40,
    -50, -40, -30, -30, -30, -30, -40, -50
  };

  final int[] BISHOP_TABLE = {
    -20, -10, -10, -10, -10, -10, -10, -20,
    -10, 0, 0, 0, 0, 0, 0, -10,
    -10, 0, 5, 10, 10, 5, 0, -10,
    -10, 5, 5, 10, 10, 5, 5, -10,
    -10, 0, 10, 10, 10, 10, 0, -10,
    -10, 10, 10, 10, 10, 10, 10, -10,
    -10, 5, 0, 0, 0, 0, 5, -10,
    -20, -10, -10, -10, -10, -10, -10, -20
  };

  final int[] ROOK_TABLE = {
    0, 0, 0, 0, 0, 0, 0, 0,
    5, 10, 10, 10, 10, 10, 10, 5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    0, 0, 0, 5, 5, 0, 0, 0
  };

  final int[] QUEEN_TABLE = {
    -20, -10, -10, -5, -5, -10, -10, -20,
    -10, 0, 0, 0, 0, 0, 0, -10,
    -10, 0, 5, 5, 5, 5, 0, -10,
    -5, 0, 5, 5, 5, 5, 0, -5,
    0, 0, 5, 5, 5, 5, 0, -5,
    -10, 5, 5, 5, 5, 5, 0, -10,
    -10, 0, 5, 0, 0, 0, 0, -10,
    -20, -10, -10, -5, -5, -10, -10, -20
  };

  final int[] KING_MIDDLE_TABLE = {
    -30, -40, -40, -50, -50, -40, -40, -30,
    -30, -40, -40, -50, -50, -40, -40, -30,
    -30, -40, -40, -50, -50, -40, -40, -30,
    -30, -40, -40, -50, -50, -40, -40, -30,
    -20, -30, -30, -40, -40, -30, -30, -20,
    -10, -20, -20, -20, -20, -20, -20, -10,
    20, 20, 0, 0, 0, 0, 20, 20,
    20, 30, 10, 0, 0, 10, 30, 20
  };

  final int[] KING_END_TABLE = {
    -50, -40, -30, -20, -20, -30, -40, -50,
    -30, -20, -10, 0, 0, -10, -20, -30,
    -30, -10, 20, 30, 30, 20, -10, -30,
    -30, -10, 30, 40, 40, 30, -10, -30,
    -30, -10, 30, 40, 40, 30, -10, -30,
    -30, -10, 20, 30, 30, 20, -10, -30,
    -30, -30, 0, 0, 0, 0, -30, -30,
    -50, -30, -30, -30, -30, -30, -30, -50
  };

  final int[] PASSED_BONUS = {0, 5, 10, 20, 35, 60, 100, 0};

  int getEvalForPiece(int pieceType) {
    switch (pieceType) {
    case 1:
    case 7:
      return 100;
    case 2:
    case 8:
      return 500;
    case 3:
    case 9:
      return 320;
    case 4:
    case 10:
      return 330;
    case 5:
    case 11:
      return 900;
    }

    return 0;
  }

  int getCurrentEval(int[][] board) {
    int eval = 0;

    int[] whitePawnsOnFile = new int[8];
    int[] blackPawnsOnFile = new int[8];
    int[] whiteMaxRow = new int[8];
    int[] blackMinRow = new int[8];
    for (int c = 0; c < 8; c++) {
      whiteMaxRow[c] = -1;
      blackMinRow[c] = 8;
    }

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        int p = board[r][c];
        if (p == 1) {
          whitePawnsOnFile[c]++;
          if (r > whiteMaxRow[c]) whiteMaxRow[c] = r;
        } else if (p == 7) {
          blackPawnsOnFile[c]++;
          if (r < blackMinRow[c]) blackMinRow[c] = r;
        }
      }
    }

    int whiteMaterial = 0;
    int blackMaterial = 0;
    int phase = 0;
    int whiteBishops = 0;
    int blackBishops = 0;
    int whiteKingRow = 0, whiteKingCol = 0;
    int blackKingRow = 0, blackKingCol = 0;
    int whiteKingTableMid = 0, whiteKingTableEnd = 0;
    int blackKingTableMid = 0, blackKingTableEnd = 0;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        int p = board[r][c];
        if (p == 0) continue;

        int wIdx = r * 8 + c;
        int bIdx = (7 - r) * 8 + c;

        switch (p) {
        case 1:
          whiteMaterial += 100;
          eval += 100 + PAWN_TABLE[wIdx];
          if (isPassedWhite(r, c, blackMinRow)) eval += PASSED_BONUS[7 - r];
          if (whitePawnsOnFile[c] > 1) eval -= 10;
          if (
            (c == 0 || whitePawnsOnFile[c - 1] == 0)
            && (c == 7 || whitePawnsOnFile[c + 1] == 0)
            ) eval -= 12;
          break;
        case 2:
          whiteMaterial += 500;
          phase += 2;
          eval += 500 + ROOK_TABLE[wIdx];
          if (whitePawnsOnFile[c] == 0) {
            eval += blackPawnsOnFile[c] == 0 ? 20 : 10;
          }
          break;
        case 3:
          whiteMaterial += 320;
          phase += 1;
          eval += 320 + KNIGHT_TABLE[wIdx];
          break;
        case 4:
          whiteMaterial += 330;
          phase += 1;
          whiteBishops++;
          eval += 330 + BISHOP_TABLE[wIdx];
          break;
        case 5:
          whiteMaterial += 900;
          phase += 4;
          eval += 900 + QUEEN_TABLE[wIdx];
          break;
        case 6:
          whiteKingRow = r;
          whiteKingCol = c;
          whiteKingTableMid = KING_MIDDLE_TABLE[wIdx];
          whiteKingTableEnd = KING_END_TABLE[wIdx];
          break;

        case 7:
          blackMaterial += 100;
          eval -= 100 + PAWN_TABLE[bIdx];
          if (isPassedBlack(r, c, whiteMaxRow)) eval -= PASSED_BONUS[r];
          if (blackPawnsOnFile[c] > 1) eval += 10;
          if (
            (c == 0 || blackPawnsOnFile[c - 1] == 0)
            && (c == 7 || blackPawnsOnFile[c + 1] == 0)
            ) eval += 12;
          break;
        case 8:
          blackMaterial += 500;
          phase += 2;
          eval -= 500 + ROOK_TABLE[bIdx];
          if (blackPawnsOnFile[c] == 0) {
            eval -= whitePawnsOnFile[c] == 0 ? 20 : 10;
          }
          break;
        case 9:
          blackMaterial += 320;
          phase += 1;
          eval -= 320 + KNIGHT_TABLE[bIdx];
          break;
        case 10:
          blackMaterial += 330;
          phase += 1;
          blackBishops++;
          eval -= 330 + BISHOP_TABLE[bIdx];
          break;
        case 11:
          blackMaterial += 900;
          phase += 4;
          eval -= 900 + QUEEN_TABLE[bIdx];
          break;
        case 12:
          blackKingRow = r;
          blackKingCol = c;
          blackKingTableMid = KING_MIDDLE_TABLE[bIdx];
          blackKingTableEnd = KING_END_TABLE[bIdx];
          break;
        }
      }
    }

    if (whiteBishops >= 2) eval += 30;
    if (blackBishops >= 2) eval -= 30;

    if (phase > 24) phase = 24;
    int whiteKing = (whiteKingTableMid * phase + whiteKingTableEnd * (24 - phase)) / 24;
    int blackKing = (blackKingTableMid * phase + blackKingTableEnd * (24 - phase)) / 24;
    eval += whiteKing - blackKing;

    int diff = whiteMaterial - blackMaterial;
    if (phase <= 8 && Math.abs(diff) >= 200) {
      int kingDist = Math.abs(whiteKingRow - blackKingRow)
        + Math.abs(whiteKingCol - blackKingCol);

      if (diff > 0) {
        eval += 10 * centerDistance(blackKingRow, blackKingCol) + 4 * (14 - kingDist);
      } else {
        eval -= 10 * centerDistance(whiteKingRow, whiteKingCol) + 4 * (14 - kingDist);
      }
    }

    return eval;
  }

  int centerDistance(int row, int col) {
    return Math.max(3 - row, row - 4) + Math.max(3 - col, col - 4);
  }

  boolean isPassedWhite(int row, int col, int[] blackMinRow) {
    for (int c = Math.max(0, col - 1); c <= Math.min(7, col + 1); c++) {
      if (blackMinRow[c] < row) return false;
    }
    return true;
  }

  boolean isPassedBlack(int row, int col, int[] whiteMaxRow) {
    for (int c = Math.max(0, col - 1); c <= Math.min(7, col + 1); c++) {
      if (whiteMaxRow[c] > row) return false;
    }
    return true;
  }

  int getEvalAfterMove(int[][] board, int from, int toPOS) {
    if (from < 0 || from >= 64 || toPOS < 0 || toPOS >= 64) {
      return getCurrentEval(board);
    }

    int[][] simulatedBoard = new int[8][8];

    for (int row = 0; row < 8; row++) {
      simulatedBoard[row] = board[row].clone();
    }

    int fromRow = from / 8;
    int fromCol = from % 8;
    int toRow = toPOS / 8;
    int toCol = toPOS % 8;

    int piece = simulatedBoard[fromRow][fromCol];

    if (piece == 0) {
      return getCurrentEval(board);
    }

    simulatedBoard[fromRow][fromCol] = 0;
    simulatedBoard[toRow][toCol] = piece;

    if (piece == 1 && toRow == 0) {
      simulatedBoard[toRow][toCol] = 5;
    } else if (piece == 7 && toRow == 7) {
      simulatedBoard[toRow][toCol] = 11;
    }

    return getCurrentEval(simulatedBoard);
  }
}
