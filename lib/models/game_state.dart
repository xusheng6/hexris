import 'package:flutter/material.dart';
import 'coordinates.dart';
import 'piece.dart';
import '../logic/square_grid_logic.dart';
import '../logic/hex_grid_logic.dart';
import '../utils/storage.dart';
import '../utils/feedback_service.dart';

class _UndoSnapshot {
  final List<List<Color?>>? squareGrid;
  final Map<HexCoord, Color>? hexGrid;
  final List<TrayPiece> tray;
  final int score;

  _UndoSnapshot({
    this.squareGrid,
    this.hexGrid,
    required this.tray,
    required this.score,
  });
}

class GameState extends ChangeNotifier {
  GameMode mode;

  // Square grid
  late List<List<Color?>> squareGrid;

  // Hex grid
  late Map<HexCoord, Color> hexGrid;

  // Tray
  late List<TrayPiece> tray;

  int score = 0;
  int highScore = 0;
  bool isGameOver = false;
  bool isAnimating = false;

  // Undo history
  final List<_UndoSnapshot> _undoStack = [];

  // Cells currently being cleared (for animation)
  Set<dynamic> cellsToClear = {};

  // Ghost preview during drag
  Set<dynamic> ghostCells = {};
  bool ghostValid = false;

  bool get canUndo => _undoStack.isNotEmpty && !isGameOver;

  GameState({this.mode = GameMode.hex, int initialHighScore = 0}) {
    highScore = initialHighScore;
    _initGrid();
    _generateTray();
  }

  void _initGrid() {
    squareGrid = SquareGridLogic.createEmptyGrid();
    hexGrid = {};
  }

  void _generateTray() {
    tray = mode == GameMode.square ? generateSquareTray() : generateHexTray();
  }

  // Deep copy helpers
  List<List<Color?>> _copySquareGrid() {
    return squareGrid.map((row) => List<Color?>.from(row)).toList();
  }

  Map<HexCoord, Color> _copyHexGrid() {
    return Map<HexCoord, Color>.from(hexGrid);
  }

  List<TrayPiece> _copyTray() {
    return tray
        .map((p) => TrayPiece(
              cells: List.from(p.cells),
              color: p.color,
              isPlaced: p.isPlaced,
            ))
        .toList();
  }

  void _saveSnapshot() {
    _undoStack.add(_UndoSnapshot(
      squareGrid: mode == GameMode.square ? _copySquareGrid() : null,
      hexGrid: mode == GameMode.hex ? _copyHexGrid() : null,
      tray: _copyTray(),
      score: score,
    ));
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final snapshot = _undoStack.removeLast();
    if (snapshot.squareGrid != null) {
      squareGrid = snapshot.squareGrid!;
    }
    if (snapshot.hexGrid != null) {
      hexGrid = snapshot.hexGrid!;
    }
    tray = snapshot.tray;
    score = snapshot.score;
    isGameOver = false;
    ghostCells = {};
    notifyListeners();
  }

  void switchMode(GameMode newMode) {
    mode = newMode;
    score = 0;
    isGameOver = false;
    cellsToClear = {};
    ghostCells = {};
    _undoStack.clear();
    _initGrid();
    _generateTray();
    Storage.loadHighScore(mode).then((hs) {
      highScore = hs;
      notifyListeners();
    });
    notifyListeners();
  }

  void setHighScore(int hs) {
    highScore = hs;
    notifyListeners();
  }

  void updateGhost(Set<dynamic> cells, bool valid) {
    ghostCells = cells;
    ghostValid = valid;
    notifyListeners();
  }

  void clearGhost() {
    if (ghostCells.isNotEmpty) {
      ghostCells = {};
      ghostValid = false;
      notifyListeners();
    }
  }

  bool placePiece(int trayIndex, dynamic anchor) {
    if (isAnimating || isGameOver) return false;
    final piece = tray[trayIndex];
    if (piece.isPlaced) return false;

    // Save state before placing
    _saveSnapshot();

    if (mode == GameMode.square) {
      final success = _placeSquare(trayIndex, anchor as SquareCoord);
      if (!success) {
        _undoStack.removeLast(); // discard snapshot if placement failed
      }
      return success;
    } else {
      final success = _placeHex(trayIndex, anchor as HexCoord);
      if (!success) {
        _undoStack.removeLast();
      }
      return success;
    }
  }

  bool _placeSquare(int trayIndex, SquareCoord anchor) {
    final piece = tray[trayIndex];
    final cells = piece.cells.cast<SquareCoord>();

    if (!SquareGridLogic.canPlace(squareGrid, cells, anchor)) return false;

    SquareGridLogic.place(squareGrid, cells, anchor, piece.color);
    piece.isPlaced = true;
    score += cells.length;

    final completed = SquareGridLogic.findCompletedLines(squareGrid);
    if (completed.isNotEmpty) {
      final lineCount = SquareGridLogic.countCompletedLines(squareGrid);
      score += completed.length + (lineCount > 1 ? lineCount * 10 : 0);
      SquareGridLogic.clearCells(squareGrid, completed);
      FeedbackService.trigger(
          lineCount > 1 ? GameSound.combo : GameSound.clear);
    } else {
      FeedbackService.trigger(GameSound.place);
    }

    _updateHighScore();
    _checkTrayRefill();
    _checkGameOver();
    if (isGameOver) FeedbackService.trigger(GameSound.gameOver);
    ghostCells = {};
    notifyListeners();
    return true;
  }

  bool _placeHex(int trayIndex, HexCoord anchor) {
    final piece = tray[trayIndex];
    final cells = piece.cells.cast<HexCoord>();

    if (!HexGridLogic.canPlace(hexGrid, cells, anchor)) return false;

    HexGridLogic.place(hexGrid, cells, anchor, piece.color);
    piece.isPlaced = true;
    score += cells.length;

    final completed = HexGridLogic.findCompletedLines(hexGrid);
    if (completed.isNotEmpty) {
      final lineCount = HexGridLogic.countCompletedLines(hexGrid);
      score += completed.length + (lineCount > 1 ? lineCount * 10 : 0);
      HexGridLogic.clearCells(hexGrid, completed);
      FeedbackService.trigger(
          lineCount > 1 ? GameSound.combo : GameSound.clear);
    } else {
      FeedbackService.trigger(GameSound.place);
    }

    _updateHighScore();
    _checkTrayRefill();
    _checkGameOver();
    if (isGameOver) FeedbackService.trigger(GameSound.gameOver);
    ghostCells = {};
    notifyListeners();
    return true;
  }

  void _checkTrayRefill() {
    // Replace each placed piece immediately with a new random one
    for (int i = 0; i < tray.length; i++) {
      if (tray[i].isPlaced) {
        final catalog = mode == GameMode.square
            ? generateSquareTray()
            : generateHexTray();
        tray[i] = catalog[0]; // grab one fresh piece
      }
    }
  }

  void _checkGameOver() {
    final remaining = tray.where((p) => !p.isPlaced).toList();
    if (remaining.isEmpty) return;

    if (mode == GameMode.square) {
      final pieceCellsList =
          remaining.map((p) => p.cells.cast<SquareCoord>()).toList();
      if (!SquareGridLogic.canFitAny(squareGrid, pieceCellsList)) {
        isGameOver = true;
      }
    } else {
      final pieceCellsList =
          remaining.map((p) => p.cells.cast<HexCoord>()).toList();
      if (!HexGridLogic.canFitAny(hexGrid, pieceCellsList)) {
        isGameOver = true;
      }
    }
  }

  void _updateHighScore() {
    if (score > highScore) {
      highScore = score;
      Storage.saveHighScore(mode, highScore);
    }
  }

  void reset() {
    score = 0;
    isGameOver = false;
    cellsToClear = {};
    ghostCells = {};
    _undoStack.clear();
    _initGrid();
    _generateTray();
    notifyListeners();
  }

  void resetHighScore() {
    highScore = 0;
    Storage.saveHighScore(mode, 0);
    notifyListeners();
  }
}
