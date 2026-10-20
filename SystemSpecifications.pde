
class SystemSpecifications {

  void setGameStatusStockfishPath() {
    String osName = System.getProperty("os.name").toLowerCase();
    String archType = System.getProperty("os.arch").toLowerCase();

    if (osName.contains("win") && (archType.equals("x86-64") || archType.equals("amd64") || archType.equals("x86_64"))) {
      gameStatus.stockfishPath = gameStatus.stockfishPathWINDOWS;
    } else if (osName.contains("linux") && (archType.equals("x86-64") || archType.equals("amd64") || archType.equals("x86_64"))) {
      gameStatus.stockfishPath = gameStatus.stockfishPathLINUXx8664;
    } else if (osName.contains("linux") && (archType.equals("arm64") || archType.equals("aarch64"))) {
      gameStatus.stockfishPath = gameStatus.sockfishPathLINUXarm64;
    }
    
    if (osName.contains("linux")) gameStatus.isLinux = true;

    println("Stockfish path: " + gameStatus.stockfishPath);
    println("OS: " + osName);
    println("Architecture: " + archType);
  }
}
