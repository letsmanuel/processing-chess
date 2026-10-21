/*
0  = Empty
 1  = White Pawn
 2  = White Rook
 3  = White Knight
 4  = White Bishop
 5  = White Queen
 6  = White King
 7  = Black Pawn
 8  = Black Rook
 9  = Black Knight
 10 = Black Bishop
 11 = Black Queen
 12 = Black King
 */

class GameStatus {
  
  float engineVersion = 0.6;
  String stockfishPathWINDOWS = "stockfish/windows.exe";
  String stockfishPathLINUXx8664 = "stockfish/linux-x86-64";
  String sockfishPathLINUXarm64 = "stockfish\\linux-arm64.tar.gz";
  boolean isLinux = false;
  
  String stockfishPath = "";
  String lossReason = "";

  int[][] fieldObject = {
    {8, 9, 10, 11, 12, 10, 9, 8},
    {7, 7, 7, 7, 7, 7, 7, 7},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {1, 1, 1, 1, 1, 1, 1, 1},
    {2, 3, 4, 5, 6, 4, 3, 2}
  };

  int[][] capturedPieces = new int[1][16];

  int enPassantTarget = -1;
  int enPassantPawnField = -1;
  boolean whiteKingSide = true;
  boolean whiteQueenSide = true;
  boolean blackKingSide = true;
  boolean blackQueenSide = true;
  int promotionChoice = 0;
  boolean promotionPending = false;
  int gameID = 0;
  int timeLimit = 600;
  int timeLimitWhite = timeLimit;
  int timeLimitBlack = timeLimit;
  boolean currentlyInCheck = false;

  int playingFieldDesign = 1;

  int lastMoveFrom = -1;
  int lastMoveTo = -1;
  
  boolean shiftDown = false;
  
  
  boolean isDrawCurrently = false;
  int halfMoveCounter = 0;
  
  boolean firstMoveDone = false;

  String[] soundQueue = {};
  
  boolean enginePlayAsBlack = true;
  boolean enginePlayAsWhite = false;
  int engineMode = 2; // 1 = Experimental (meine), 2 = Smart (Stockfish), 3 = Auto (beides)
  int stockfishElo = 3200;
  int engineMode3Choice = 2;
  int stockfishMaxThinkingTime = 500;
}
