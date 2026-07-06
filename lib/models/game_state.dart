import 'dart:convert';
import 'package:flutter/material.dart';
import 'coordinates.dart';
import 'piece.dart';
import '../logic/square_grid_logic.dart';
import '../logic/hex_grid_logic.dart';
import '../utils/constants.dart';
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
  DateTime? highScoreDate;
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

  GameState({
    this.mode = GameMode.hex,
    int initialHighScore = 0,
    DateTime? initialHighScoreDate,
    Map<String, dynamic>? savedState,
  }) {
    highScore = initialHighScore;
    highScoreDate = initialHighScoreDate;
    if (savedState != null && _tryRestore(savedState)) {
      return;
    }
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
    _persist();
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
    _persist();
    Storage.loadHighScore(mode).then((hs) async {
      highScore = hs;
      highScoreDate = await Storage.loadHighScoreDate(mode);
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
      FeedbackService.trigger(
          lineCount > 1 ? GameSound.combo : GameSound.clear);
      // Start clear animation — cells stay visible during animation
      cellsToClear = completed;
      isAnimating = true;
      _updateHighScore();
      _checkTrayRefill();
      ghostCells = {};
      notifyListeners();
      // After animation, actually remove the cells
      Future.delayed(GameConstants.clearAnimationDuration, () {
        SquareGridLogic.clearCells(squareGrid, completed);
        cellsToClear = {};
        isAnimating = false;
        _checkGameOver();
        if (isGameOver) FeedbackService.trigger(GameSound.gameOver);
        _persist();
        notifyListeners();
      });
    } else {
      FeedbackService.trigger(GameSound.place);
      _updateHighScore();
      _checkTrayRefill();
      _checkGameOver();
      if (isGameOver) FeedbackService.trigger(GameSound.gameOver);
      ghostCells = {};
      _persist();
      notifyListeners();
    }

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
      FeedbackService.trigger(
          lineCount > 1 ? GameSound.combo : GameSound.clear);
      cellsToClear = completed;
      isAnimating = true;
      _updateHighScore();
      _checkTrayRefill();
      ghostCells = {};
      notifyListeners();
      Future.delayed(GameConstants.clearAnimationDuration, () {
        HexGridLogic.clearCells(hexGrid, completed);
        cellsToClear = {};
        isAnimating = false;
        _checkGameOver();
        if (isGameOver) FeedbackService.trigger(GameSound.gameOver);
        _persist();
        notifyListeners();
      });
    } else {
      FeedbackService.trigger(GameSound.place);
      _updateHighScore();
      _checkTrayRefill();
      _checkGameOver();
      if (isGameOver) FeedbackService.trigger(GameSound.gameOver);
      ghostCells = {};
      _persist();
      notifyListeners();
    }

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
      highScoreDate = DateTime.now();
      Storage.saveHighScore(mode, highScore, highScoreDate!);
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
    _persist();
    notifyListeners();
  }

  /// Clears the saved high score and date for every mode.
  Future<void> resetAllHighScores() async {
    for (final m in GameMode.values) {
      await Storage.clearHighScore(m);
    }
    highScore = 0;
    highScoreDate = null;
    notifyListeners();
  }

  // --- Persistence -----------------------------------------------------------

  /// Serialize the current board, tray, score and mode so the game can be
  /// resumed after the app is closed. The undo history and in-flight clear
  /// animation are intentionally not persisted.
  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'score': score,
      'isGameOver': isGameOver,
      if (mode == GameMode.square)
        'squareGrid': squareGrid
            .map((row) => row.map((c) => c?.toARGB32()).toList())
            .toList(),
      if (mode == GameMode.hex)
        'hexGrid': hexGrid.entries
            .map((e) =>
                {'q': e.key.q, 'r': e.key.r, 'c': e.value.toARGB32()})
            .toList(),
      'tray': tray.map((p) {
        return {
          'cells': p.cells.map((cell) {
            if (cell is SquareCoord) {
              return {'row': cell.row, 'col': cell.col};
            }
            final h = cell as HexCoord;
            return {'q': h.q, 'r': h.r};
          }).toList(),
          'color': p.color.toARGB32(),
          'isPlaced': p.isPlaced,
        };
      }).toList(),
    };
  }

  /// Write the current state to disk (fire-and-forget). Called after every
  /// state-changing move so a quit at any point can be recovered.
  void _persist() {
    Storage.saveGame(jsonEncode(toJson()));
  }

  /// Persist the current state. Safe to call from an app-lifecycle handler.
  void save() => _persist();

  /// Attempt to rebuild the board, tray, score and mode from [json]. Returns
  /// false (leaving the game untouched) if the snapshot is malformed, so the
  /// caller can fall back to a fresh game.
  bool _tryRestore(Map<String, dynamic> json) {
    try {
      mode = GameMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => mode,
      );
      score = json['score'] as int? ?? 0;
      isGameOver = json['isGameOver'] as bool? ?? false;

      squareGrid = SquareGridLogic.createEmptyGrid();
      hexGrid = {};

      if (mode == GameMode.square && json['squareGrid'] != null) {
        final rows = json['squareGrid'] as List;
        for (int r = 0; r < rows.length && r < squareGrid.length; r++) {
          final cols = rows[r] as List;
          for (int c = 0; c < cols.length && c < squareGrid[r].length; c++) {
            final v = cols[c];
            if (v != null) squareGrid[r][c] = Color(v as int);
          }
        }
      } else if (mode == GameMode.hex && json['hexGrid'] != null) {
        for (final e in (json['hexGrid'] as List)) {
          hexGrid[HexCoord(e['q'] as int, e['r'] as int)] =
              Color(e['c'] as int);
        }
      }

      final trayJson = json['tray'] as List;
      tray = trayJson.map((p) {
        final cells = (p['cells'] as List).map<dynamic>((cell) {
          if (mode == GameMode.square) {
            return SquareCoord(cell['row'] as int, cell['col'] as int);
          }
          return HexCoord(cell['q'] as int, cell['r'] as int);
        }).toList();
        return TrayPiece(
          cells: cells,
          color: Color(p['color'] as int),
          isPlaced: p['isPlaced'] as bool? ?? false,
        );
      }).toList();

      if (tray.isEmpty) return false;
      return true;
    } catch (_) {
      return false;
    }
  }
}
