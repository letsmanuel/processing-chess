# Chess.Processing

A chess game built with Java and [Processing](https://processing.org/), featuring a custom chess implementation, Stockfish engine integration, move evaluation, and a graphical interface.

[**Download Latest Development Build**](https://github.com/letsmanuel/processing-chess/releases/tag/chess-dev) · [**Source Code**](https://github.com/letsmanuel/processing-chess) · [**Report a Bug**](https://github.com/letsmanuel/processing-chess/issues)

> **Development status:** This project is actively developed. Development builds may contain bugs or unfinished features.

## Features

- **Chess engine:** Custom move generation and legal move validation.
- **Stockfish integration:** Play against Stockfish with configurable engine strength and thinking time.
- **Move evaluation:** Position evaluation and a visual evaluation bar.
- **Legal move highlighting:** Visual feedback for available moves.
- **Move history:** A dedicated move list for tracking the current game.
- **Game timers:** Time tracking for both sides.
- **Promotion handling:** Support for choosing a promotion piece.
- **Game status:** Check detection, checkmate handling, and draw handling.
- **Sound effects:** Audio feedback for moves, captures, checks, and other game events.
- **Customizable interface:** Settings, board rendering, overlays, animations, and graphical controls.
- **Performance information:** System specifications and engine-related configuration.

## Screenshots

Screenshots will be added as the interface develops.

## Download

The easiest way to try the game is to download a prebuilt Windows version.

1. Open the [latest chess-dev release](https://github.com/letsmanuel/processing-chess/releases/tag/chess-dev).
2. Download `chess-windows.zip`.
3. Extract the ZIP file into a directory of your choice.
4. Run the exported application executable from the extracted directory.

Keep the application's accompanying files and directories together. The `data` directory contains resources required by the game, including images, sounds, chess-piece graphics, and the Stockfish executable.

Development builds are automatically updated when a build succeeds. The latest development version may differ from the source code in an older downloaded release.

## Running from source

### Requirements

- [Processing](https://processing.org/) 4
- The Processing Sound library
- A compatible Java runtime provided by the Processing environment
- Git, if you want to clone the repository

### Setup

Clone the repository:

```bash
git clone https://github.com/letsmanuel/processing-chess.git
cd processing-chess
```

Open `chess_base_layout.pde` in Processing and run the sketch.

**Important:** Keep the supporting `.pde` files and the `data` directory in the project. The main sketch depends on classes defined in other source files, and the game loads its graphics, audio, and engine resources from `data`.

### Stockfish

Chess.Processing integrates Stockfish through its own engine bridge. The repository includes a Stockfish executable under `data/stockfish/`.

The application uses its engine configuration to control settings such as playing strength and thinking time. Engine startup can fail if the executable is missing, incompatible with the operating system, or cannot be launched.

## Project structure

```text
processing-chess/
├── .github/
│   └── workflows/
│       └── release.yml
├── data/
│   ├── images/
│   ├── overlay-assets/
│   ├── pieces/
│   ├── sound/
│   └── stockfish/
├── ButtonRenderer.pde
├── ChessEngine.pde
├── GameStatus.pde
├── LastMoveListRenderer.pde
├── LegalMoves.pde
├── MoveRating.pde
├── OverlayRenderer.pde
├── PieceRenderer.pde
├── PositionEvaluator.pde
├── PowerBarRenderer.pde
├── RendererBaseLayout.pde
├── SettingsRenderer.pde
├── SoundManager.pde
├── StockfishBridge.pde
├── SystemSpecifications.pde
├── TimeRenderer.pde
├── UIComponents.pde
├── chess_base_layout.pde
├── sketch.properties
├── .gitignore
└── LICENSE
```

### Source code overview

| File | Responsibility |
| --- | --- |
| `chess_base_layout.pde` | Main Processing sketch and game loop |
| `GameStatus.pde` | Central game state and configuration |
| `ChessEngine.pde` | Chess engine and game logic |
| `LegalMoves.pde` | Legal move generation and validation |
| `PositionEvaluator.pde` | Position evaluation |
| `StockfishBridge.pde` | Communication with Stockfish |
| `PieceRenderer.pde` | Chess-piece rendering |
| `RendererBaseLayout.pde` | Main board rendering |
| `ButtonRenderer.pde` | Button rendering |
| `UIComponents.pde` | Shared interface components |
| `OverlayRenderer.pde` | Game overlays, animations, and status displays |
| `SettingsRenderer.pde` | Game and engine settings |
| `LastMoveListRenderer.pde` | Move history display |
| `MoveRating.pde` | Move-rating functionality |
| `PowerBarRenderer.pde` | Position evaluation bar |
| `TimeRenderer.pde` | Player timers |
| `SoundManager.pde` | Sound effects |
| `SystemSpecifications.pde` | System detection and engine configuration |

The `data` directory contains the application's visual and audio resources alongside the bundled Stockfish executable and its supporting files.

## Automated builds

This repository uses GitHub Actions to build and publish development releases.
Markdown-only changes are excluded from automatic push-triggered builds.

### Download builds

Find published development builds on the [GitHub Releases page](https://github.com/letsmanuel/processing-chess/releases).

## Contributing

Contributions, bug reports, and suggestions are welcome.

1. Fork the repository.
2. Create a branch for your changes.
3. Make and test your changes in Processing.
4. Open a pull request describing the changes.

For bug reports, include the operating system, relevant error messages, and steps to reproduce the issue.

See [`CONTRIBUTING.md`](CONTRIBUTING.md) if contribution guidelines are available in your checkout.

## License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. See [`LICENSE`](LICENSE) for the full license text.

Stockfish and other bundled dependencies may have their own licensing terms. Refer to their respective license files for details.

## Acknowledgements

- [Processing](https://processing.org/) for the creative coding environment.
- [Stockfish](https://stockfishchess.org/) for the chess engine.
- The developers and contributors of the open-source tools and libraries used by this project.

---

Made with Processing and Java.
