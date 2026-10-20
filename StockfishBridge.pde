import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

class StockfishBridge {

  Process process;
  BufferedWriter toEngine;
  LinkedBlockingQueue<String> lines = new LinkedBlockingQueue<String>();

  volatile boolean ready = false;
  int lastScore = 0;
  int lastDepth = 0;
  char lastPromotion = ' ';
  String lastError = "";

  boolean start(String exePath, int threads, int hashMb) {
    stop();

    try {
      ProcessBuilder builder;

      if (gameStatus.isLinux) {
        println("Stockfish is linux booting");
        java.io.File executable = new java.io.File(exePath).getCanonicalFile();

        if (!executable.isFile() || !executable.canExecute()) {
          lastError = "Stockfish is not executable: " + executable
            + " (exists=" + executable.exists()
            + ", executable=" + executable.canExecute() + ")";
          return false;
        }

        builder = new ProcessBuilder("./" + executable.getName());
        builder.directory(executable.getParentFile());
      } else {
        builder = new ProcessBuilder(exePath);
      }

      builder.redirectErrorStream(true);
      process = builder.start();

      toEngine = new BufferedWriter(
        new OutputStreamWriter(process.getOutputStream())
        );

      final BufferedReader reader = new BufferedReader(
        new InputStreamReader(process.getInputStream())
        );

      Thread readerThread = new Thread(() -> {
        try {
          String line;

          while ((line = reader.readLine()) != null) {
            lines.add(line);
          }
        }
        catch (Exception e) {
        }
      }
      );

      readerThread.setDaemon(true);
      readerThread.start();

      send("uci");

      if (!waitFor("uciok", 5000)) {
        lastError = "Engine did not answer 'uci'";
        stop();
        return false;
      }

      send("setoption name Threads value " + threads);
      send("setoption name Hash value " + hashMb);
      send("isready");

      if (!waitFor("readyok", 5000)) {
        lastError = "Engine did not answer 'isready'";
        stop();
        return false;
      }

      Runtime.getRuntime().addShutdownHook(new Thread(() -> stop()));

      ready = true;
      return true;
    }
    catch (Exception e) {
      lastError = e.toString();
      stop();
      return false;
    }
  }

  void stop() {
    ready = false;

    try {
      if (toEngine != null) send("quit");
    }
    catch (Exception e) {
    }

    if (process != null) process.destroy();

    process = null;
    toEngine = null;
    lines.clear();
  }

  void setStrength(int elo) {
    if (!ready) return;

    if (elo <= 0) {
      send("setoption name UCI_LimitStrength value false");
    } else {
      int clamped = Math.max(1320, Math.min(3190, elo));
      send("setoption name UCI_LimitStrength value true");
      send("setoption name UCI_Elo value " + clamped);
    }
  }

  synchronized int[] bestMove(String fen, int movetimeMs) {
    if (!ready) return null;

    lines.clear();
    lastPromotion = ' ';

    send("position fen " + fen);
    send("go movetime " + movetimeMs);

    long end = System.currentTimeMillis() + movetimeMs + 5000;

    try {
      while (System.currentTimeMillis() < end) {
        String line = lines.poll(100, TimeUnit.MILLISECONDS);
        if (line == null) continue;

        if (line.startsWith("info") && line.contains(" score ")) {
          parseInfo(line);
        } else if (line.startsWith("bestmove")) {
          String[] parts = line.split(" ");
          if (parts.length < 2) return null;
          return uciToFields(parts[1]);
        }
      }
    }
    catch (InterruptedException e) {
    }

    send("stop");
    return null;
  }

  synchronized int scoreCp(String fen, int movetimeMs) {
    int[] move = bestMove(fen, movetimeMs);
    return lastScore;
  }

  void parseInfo(String line) {
    String[] t = line.split(" ");

    for (int i = 0; i < t.length - 2; i++) {
      if (t[i].equals("depth")) {
        try {
          lastDepth = Integer.parseInt(t[i + 1]);
        }
        catch (Exception e) {
        }
      }

      if (t[i].equals("score")) {
        try {
          int value = Integer.parseInt(t[i + 2]);

          if (t[i + 1].equals("cp")) {
            lastScore = value;
          } else if (t[i + 1].equals("mate")) {
            int sign = value >= 0 ? 1 : -1;
            lastScore = sign * (100000 - 2 * Math.abs(value));
          }
        }
        catch (Exception e) {
        }
      }
    }
  }

  int[] uciToFields(String move) {
    if (move == null || move.length() < 4 || move.equals("(none)")) return null;

    int fromCol = move.charAt(0) - 'a';
    int fromRow = 8 - (move.charAt(1) - '0');
    int toCol = move.charAt(2) - 'a';
    int toRow = 8 - (move.charAt(3) - '0');

    if (fromCol < 0 || fromCol > 7 || toCol < 0 || toCol > 7) return null;
    if (fromRow < 0 || fromRow > 7 || toRow < 0 || toRow > 7) return null;

    if (move.length() >= 5) lastPromotion = move.charAt(4);

    return new int[] {fromRow * 8 + fromCol, toRow * 8 + toCol};
  }

  String buildFen(int[][] board, boolean whiteToMove,
    boolean whiteKingSide, boolean whiteQueenSide,
    boolean blackKingSide, boolean blackQueenSide, int enPassantTarget) {

    String letters = ".PRNBQKprnbqk";
    StringBuilder fen = new StringBuilder();

    for (int row = 0; row < 8; row++) {
      int empty = 0;

      for (int col = 0; col < 8; col++) {
        int piece = board[row][col];

        if (piece == 0) {
          empty++;
        } else {
          if (empty > 0) fen.append(empty);
          empty = 0;
          fen.append(letters.charAt(piece));
        }
      }

      if (empty > 0) fen.append(empty);
      if (row < 7) fen.append('/');
    }

    fen.append(whiteToMove ? " w " : " b ");

    String castling = "";
    if (whiteKingSide) castling += "K";
    if (whiteQueenSide) castling += "Q";
    if (blackKingSide) castling += "k";
    if (blackQueenSide) castling += "q";
    fen.append(castling.length() > 0 ? castling : "-");

    if (enPassantTarget >= 0 && enPassantTarget < 64) {
      fen.append(' ');
      fen.append((char) ('a' + enPassantTarget % 8));
      fen.append(8 - enPassantTarget / 8);
    } else {
      fen.append(" -");
    }

    fen.append(" 0 1");
    return fen.toString();
  }

  synchronized void send(String command) {
    try {
      toEngine.write(command);
      toEngine.newLine();
      toEngine.flush();
    }
    catch (Exception e) {
      lastError = e.toString();
    }
  }

  boolean waitFor(String prefix, int timeoutMs) {
    long end = System.currentTimeMillis() + timeoutMs;

    try {
      while (System.currentTimeMillis() < end) {
        String line = lines.poll(100, TimeUnit.MILLISECONDS);
        if (line != null && line.startsWith(prefix)) return true;
      }
    }
    catch (InterruptedException e) {
    }

    return false;
  }
}
