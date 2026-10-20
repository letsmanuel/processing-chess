class PieceRenderer {
  RendererBaseLayout rendererBaseLayout = new RendererBaseLayout();
  int elementSize = rendererBaseLayout.elementSize;

  PShape[] pieces = new PShape[13];

  int[][] lastBoard = new int[8][8];
  boolean hasLastBoard = false;
  ArrayList<PieceAnimation> animations = new ArrayList<PieceAnimation>();
  int moveDurationMs = 180;

  class PieceAnimation {
    int piece;
    int fromField;
    int toField;
    int captured;
    int startMillis;

    PieceAnimation(int piece, int fromField, int toField, int captured, int startMillis) {
      this.piece = piece;
      this.fromField = fromField;
      this.toField = toField;
      this.captured = captured;
      this.startMillis = startMillis;
    }
  }



  void init() {
    pieces[0] = null;
    pieces[1] = loadShape("pieces/white_pawn.svg");
    pieces[2] = loadShape("pieces/white_rook.svg");
    pieces[3] = loadShape("pieces/white_knight.svg");
    pieces[4] = loadShape("pieces/white_bishop.svg");
    pieces[5] = loadShape("pieces/white_queen.svg");
    pieces[6] = loadShape("pieces/white_king.svg");
    pieces[7] = loadShape("pieces/black_pawn.svg");
    pieces[8] = loadShape("pieces/black_rook.svg");
    pieces[9] = loadShape("pieces/black_knight.svg");
    pieces[10] = loadShape("pieces/black_bishop.svg");
    pieces[11] = loadShape("pieces/black_queen.svg");
    pieces[12] = loadShape("pieces/black_king.svg");
  }

  void drawPieces(int[][] board) {
    detectMoves(board);

    int now = millis();

    for (int i = animations.size() - 1; i >= 0; i--) {
      if (now - animations.get(i).startMillis >= moveDurationMs) {
        animations.remove(i);
      }
    }

    for (int pos = 0; pos < 64; pos++) {
      PieceAnimation anim = animationTo(pos);

      if (anim != null) {
        drawPiece(anim.captured, pos);
      } else {
        drawPiece(board[pos / 8][pos % 8], pos);
      }
    }

    for (PieceAnimation anim : animations) {
      float t = constrain((now - anim.startMillis) / (float) moveDurationMs, 0, 1);
      float eased = t * t * (3 - 2 * t);

      float fromX = (anim.fromField % 8) * elementSize;
      float fromY = (anim.fromField / 8) * elementSize;
      float toX = (anim.toField % 8) * elementSize;
      float toY = (anim.toField / 8) * elementSize;

      shape(
        pieces[anim.piece],
        lerp(fromX, toX, eased),
        lerp(fromY, toY, eased),
        elementSize,
        elementSize
        );
    }
  }

  PieceAnimation animationTo(int fieldID) {
    for (PieceAnimation anim : animations) {
      if (anim.toField == fieldID) return anim;
    }
    return null;
  }

  void detectMoves(int[][] board) {
    if (!hasLastBoard) {
      copyBoard(board);
      hasLastBoard = true;
      return;
    }

    ArrayList<Integer> gained = new ArrayList<Integer>();
    ArrayList<Integer> lost = new ArrayList<Integer>();

    for (int pos = 0; pos < 64; pos++) {
      int oldPiece = lastBoard[pos / 8][pos % 8];
      int newPiece = board[pos / 8][pos % 8];

      if (oldPiece == newPiece) continue;
      if (newPiece != 0) gained.add(pos);
      if (oldPiece != 0) lost.add(pos);
    }

    if (gained.size() > 0 && gained.size() <= 4) {
      ArrayList<PieceAnimation> found = new ArrayList<PieceAnimation>();

      for (int target : gained) {
        int piece = board[target / 8][target % 8];
        int source = findSource(lost, target, piece);

        boolean promotionPiece = (piece >= 2 && piece <= 5) || (piece >= 8 && piece <= 11);
        if (source == -1 && promotionPiece) {
          source = findSource(lost, target, piece <= 6 ? 1 : 7);
        }

        if (source == -1) continue;

        lost.remove(Integer.valueOf(source));

        int captured = lastBoard[target / 8][target % 8];
        found.add(new PieceAnimation(piece, source, target, captured, millis()));
      }

      if (found.size() > 0) {
        animations.clear();
        animations.addAll(found);
      }
    } else if (gained.size() > 4) {
      animations.clear();
    }

    copyBoard(board);
  }

  int findSource(ArrayList<Integer> lost, int target, int piece) {
    int best = -1;
    int bestDistance = 1000;

    for (int pos : lost) {
      if (pos == target) continue;
      if (lastBoard[pos / 8][pos % 8] != piece) continue;

      int distance = abs(pos % 8 - target % 8) + abs(pos / 8 - target / 8);

      if (distance < bestDistance) {
        bestDistance = distance;
        best = pos;
      }
    }

    return best;
  }

  void copyBoard(int[][] board) {
    for (int row = 0; row < 8; row++) {
      System.arraycopy(board[row], 0, lastBoard[row], 0, 8);
    }
  }

  void drawPiece(int pieceID, int fieldID) {
    if (pieceID <= 0 || pieceID >= pieces.length) return;
    if (fieldID < 0 || fieldID >= 64) return;
    if (pieces[pieceID] == null) return;

    int x = (fieldID % 8) * elementSize;
    int y = (fieldID / 8) * elementSize;

    shape(pieces[pieceID], x, y, elementSize, elementSize);
  }
}
