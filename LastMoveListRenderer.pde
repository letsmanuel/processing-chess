class LastMoveListRenderer {

  PShape[] pieces = new PShape[13];

  float listX = 440;
  float listY = 45;
  float listW = 150;
  float listH = 200;
  float rowH = 24;
  float iconSize = 16;

  float scroll = 0;
  float scrollSpeed = 0.15;

  ArrayList<Row> rows = new ArrayList<Row>();
  int latestRow = -1;
  boolean latestIsWhite = true;

  class Entry {
    String label;
    int icon;

    Entry(String label, int icon) {
      this.label = label;
      this.icon = icon;
    }
  }

  class Row {
    int number;
    Entry white;
    Entry black;

    Row(int number) {
      this.number = number;
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

  void clearLastMoves() {
    rows.clear();
    latestRow = -1;
    latestIsWhite = true;
    scroll = 0;
  }

  void pushNewMove(int from, int toPOS) {
    if (from < 0 || from >= 64 || toPOS < 0 || toPOS >= 64) return;

    int[][] board = gameStatus.fieldObject;
    int piece = board[from / 8][from % 8];
    if (piece == 0) return;

    int target = board[toPOS / 8][toPOS % 8];
    boolean white = piece <= 6;
    boolean pawn = piece == 1 || piece == 7;
    boolean castle = (piece == 6 || piece == 12) && abs(toPOS % 8 - from % 8) == 2;
    boolean enPassant = pawn && target == 0 && from % 8 != toPOS % 8;
    boolean capture = target != 0 || enPassant;
    boolean promotion = (piece == 1 && toPOS / 8 == 0) || (piece == 7 && toPOS / 8 == 7);

    String square = squareName(toPOS);
    String label;
    int icon = 0;

    if (castle) {
      label = (toPOS % 8 > from % 8) ? "O-O" : "O-O-O";
    } else if (pawn) {
      label = capture ? fileLetter(from) + "x" + square : square;
      if (promotion) label += "=D";
    } else {
      icon = piece;
      label = (capture ? "x" : "") + square;
    }

    Entry entry = new Entry(label, icon);

    if (white) {
      Row row = new Row(rows.size() + 1);
      row.white = entry;
      rows.add(row);
    } else {
      Row last = rows.size() > 0 ? rows.get(rows.size() - 1) : null;

      if (last != null && last.white != null && last.black == null) {
        last.black = entry;
      } else {
        Row row = new Row(rows.size() + 1);
        row.black = entry;
        rows.add(row);
      }
    }

    latestRow = rows.size() - 1;
    latestIsWhite = white;
  }

  void setPromotion(int pieceID) {
    if (latestRow < 0) return;

    Row row = rows.get(latestRow);
    Entry entry = latestIsWhite ? row.white : row.black;
    if (entry == null) return;

    int eq = entry.label.indexOf("=");
    if (eq < 0) return;

    String letter = "D";
    int type = (pieceID - 1) % 6;
    if (type == 1) letter = "T";
    else if (type == 2) letter = "S";
    else if (type == 3) letter = "L";

    entry.label = entry.label.substring(0, eq) + "=" + letter;
  }

  void tickLastMoves() {
    float maxScroll = max(0, rows.size() * rowH - listH);

    scroll = lerp(scroll, maxScroll, scrollSpeed);
    if (abs(maxScroll - scroll) < 0.1) scroll = maxScroll;

    pushStyle();

    noStroke();
    fill(40, 44, 58);
    rect(listX, listY, listW, listH, 8);

    clip(listX, listY, listW, listH);

    textSize(14);
    textAlign(LEFT, CENTER);

    float numberW = 34;
    float cellW = (listW - numberW) / 2;

    for (int i = 0; i < rows.size(); i++) {
      float y = listY + i * rowH - scroll;

      if (y + rowH < listY || y > listY + listH) continue;

      Row row = rows.get(i);

      if (i % 2 == 1) {
        noStroke();
        fill(46, 50, 66);
        rect(listX, y, listW, rowH);
      }

      fill(140);
      text(row.number + ".", listX + 8, y + rowH / 2);

      drawEntry(row.white, listX + numberW, y, cellW, i == latestRow && latestIsWhite);
      drawEntry(row.black, listX + numberW + cellW, y, cellW, i == latestRow && !latestIsWhite);
    }

    noClip();
    popStyle();
  }

  void drawEntry(Entry entry, float x, float y, float cellW, boolean latest) {
    if (entry == null) return;

    if (latest) {
      noStroke();
      fill(70, 78, 100);
      rect(x - 3, y + 2, cellW - 4, rowH - 4, 5);
    }

    float textX = x + 2;

    if (entry.icon > 0 && pieces[entry.icon] != null) {
      shape(pieces[entry.icon], x + 2, y + (rowH - iconSize) / 2, iconSize, iconSize);
      textX += iconSize + 3;
    }

    fill(255);
    text(entry.label, textX, y + rowH / 2 - 1);
  }

  String fileLetter(int fieldID) {
    return str((char) ('a' + fieldID % 8));
  }

  String squareName(int fieldID) {
    return fileLetter(fieldID) + (8 - fieldID / 8);
  }
}
