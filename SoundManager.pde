import processing.sound.*;

class SoundManager {
  PApplet sketch;
  SoundFile moveSound;
  SoundFile captureSound;
  SoundFile checkSound;
  SoundFile promoteSound;
  SoundFile notifySound;
  SoundFile illegalSound;
  SoundFile gameEndSound;
  SoundFile clickSound;

  SoundManager(PApplet sketch) {
    this.sketch = sketch;
    moveSound = new SoundFile(sketch, "sound/move-self.wav");
    captureSound = new SoundFile(sketch, "sound/capture.wav");
    checkSound = new SoundFile(sketch, "sound/move-check.wav");
    promoteSound = new SoundFile(sketch, "sound/promote.wav");
    notifySound = new SoundFile(sketch, "sound/notify.wav");
    illegalSound = new SoundFile(sketch, "sound/illegal.wav");
    gameEndSound = new SoundFile(sketch, "sound/game-end.wav");
    clickSound = new SoundFile(sketch, "sound/click.wav");
  }


  void playSoundById(String soundID) {
    switch (soundID) {
    case "move":
      moveSound.play();
      break;
    case "capture":
      captureSound.play();
      break;
    case "check":
      checkSound.play();
      break;
    case "promote":
      promoteSound.play();
      break;
    case "notify":
      notifySound.play();
      break;
    case "illegal":
      illegalSound.play();
      break;
    case "gameEnd":
      gameEndSound.play();
      break;
    case "click":
      clickSound.play();
      break;
  }
  }
}
