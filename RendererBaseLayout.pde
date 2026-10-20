class RendererBaseLayout {

  int designs[][][] = {
    { { 229, 199, 146 }, { 133, 95, 61 } }, // Classic wood
    { { 238, 238, 210 }, { 118, 150, 86 } }, // Tournament green
    { { 222, 227, 230 }, { 140, 162, 173 } }, // Ice blue
    { { 240, 217, 181 }, { 181, 136, 99 } }, // Walnut
    { { 234, 233, 210 }, {  75, 115, 153 } }, // Ocean
    { { 245, 222, 233 }, { 172, 107, 148 } }, // Rose
    { { 205, 210, 215 }, {  70, 75, 80 } }, // Slate gray
    { { 255, 233, 181 }, { 207, 99, 45 } }, // Sunset orange
    { { 224, 214, 245 }, { 110, 80, 160 } }, // Lavender purple
    { { 200, 230, 215 }, {  40, 100, 80 } }, // Mint & forest
    { { 250, 235, 215 }, { 140, 35, 45 } }   // Cream & burgundy
  };

  int elementSize = 50;

  void drawLegalMoves(int design, int selectedFieldID, int[] legalMoveIDs) {
    int[][] designReferenceData = designs[design];

    ellipseMode(CORNERS);
    noStroke();

    for (int legalMoveObject = 0; legalMoveObject < legalMoveIDs.length; legalMoveObject++) {
      int currentFieldID = legalMoveIDs[legalMoveObject];

      if (currentFieldID < 0 || currentFieldID >= 64) continue;
      if (currentFieldID == selectedFieldID) continue;

      int row = currentFieldID / 8;
      int element = currentFieldID % 8;

      boolean colorChoice = (row % 2 != element % 2);
      colorChoice = !colorChoice;

      int colorIndex = colorChoice ? 0 : 1;

      fill(color(
        constrain(designReferenceData[colorIndex][0] - 50, 0, 255),
        constrain(designReferenceData[colorIndex][1] - 50, 0, 255),
        constrain(designReferenceData[colorIndex][2] - 50, 0, 255),
        255
        ));

      ellipse(
        (element * elementSize) + (elementSize / 4),
        (row * elementSize) + (elementSize / 4),
        (element * elementSize) + elementSize - (elementSize / 4),
        (row * elementSize) + elementSize - (elementSize / 4)
        );
    }
  }

  int getKingFieldID(boolean white) {
    int king = white ? 6 : 12;
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        if (gameStatus.fieldObject[row][col] == king) return row * 8 + col;
      }
    }
    return -1;
  }

  void drawPlayingField(int design, int selectedFieldID) {
    background(10, 10, 10);
    int [][]designReferenceData = designs[design];
    color designColor1 = color(designReferenceData[0][0], designReferenceData[0][1], designReferenceData[0][2]);
    color designColor2 = color(designReferenceData[1][0], designReferenceData[1][1], designReferenceData[1][2]);
    
    for (int row = 0; row < 8; row++) {
      for (int element = 0; element < 8; element++) {
        int currentFieldID = (row * 8) + element;
        boolean colorChoice = true;
        boolean isSelectedField = (selectedFieldID == currentFieldID);
        if (row % 2 == 0) colorChoice = !colorChoice;
        if (element % 2 == 0) colorChoice = !colorChoice;

        color elementColor = color(0, 0, 0);

        if (colorChoice) elementColor = designColor1;
        if (!colorChoice) elementColor = designColor2;

        if (isSelectedField) {
          if (colorChoice) {
            elementColor = color(
              constrain(designReferenceData[0][0] + 50, 0, 255),
              constrain(designReferenceData[0][1] + 50, 0, 255),
              constrain(designReferenceData[0][2] + 50, 0, 255),
              255
              );
          } else {
            elementColor = color(
              constrain(designReferenceData[1][0] + 50, 0, 255),
              constrain(designReferenceData[1][1] + 50, 0, 255),
              constrain(designReferenceData[1][2] + 50, 0, 255),
              255
              );
          }
        }

        if (gameStatus.lastMoveFrom == currentFieldID || gameStatus.lastMoveTo == currentFieldID) {
          int[] base = colorChoice ? designReferenceData[0] : designReferenceData[1];
          color baseColor = color(base[0], base[1], base[2]);
          elementColor = lerpColor(baseColor, color(255, 235, 90), 0.55);
        }
        
        if (gameStatus.currentlyInCheck && getKingFieldID(whiteTurn) == currentFieldID) {
          elementColor = color(251, 84, 43);
        }

        if (!isSelectedField) noStroke();
        if (isSelectedField) stroke(10);
        fill(elementColor);
        rect((element * elementSize), (row * elementSize), elementSize, elementSize);
      }
    }
  }
}
