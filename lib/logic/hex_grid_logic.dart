import 'package:flutter/material.dart';
import '../models/coordinates.dart';
import '../utils/constants.dart';

class HexGridLogic {
  static final Set<HexCoord> boardCells =
      generateHexBoard(GameConstants.hexRadius);

  // Pre-computed lines for each of the 3 axes
  static final Map<int, List<HexCoord>> _qLines = _buildLines((c) => c.q);
  static final Map<int, List<HexCoord>> _rLines = _buildLines((c) => c.r);
  static final Map<int, List<HexCoord>> _sLines = _buildLines((c) => c.s);

  static Map<int, List<HexCoord>> _buildLines(int Function(HexCoord) axis) {
    final map = <int, List<HexCoord>>{};
    for (final cell in boardCells) {
      final key = axis(cell);
      map.putIfAbsent(key, () => []).add(cell);
    }
    return map;
  }

  /// Check if piece can be placed at anchor position.
  static bool canPlace(
    Map<HexCoord, Color> grid,
    List<HexCoord> pieceCells,
    HexCoord anchor,
  ) {
    for (final cell in pieceCells) {
      final pos = anchor + cell;
      if (!boardCells.contains(pos)) return false;
      if (grid.containsKey(pos)) return false;
    }
    return true;
  }

  /// Place piece on grid. Returns placed cell coords.
  static List<HexCoord> place(
    Map<HexCoord, Color> grid,
    List<HexCoord> pieceCells,
    HexCoord anchor,
    Color color,
  ) {
    final placed = <HexCoord>[];
    for (final cell in pieceCells) {
      final pos = anchor + cell;
      grid[pos] = color;
      placed.add(pos);
    }
    return placed;
  }

  /// Find all cells on completed lines (3 axes).
  static Set<HexCoord> findCompletedLines(Map<HexCoord, Color> grid) {
    final toClear = <HexCoord>{};

    void checkAxis(Map<int, List<HexCoord>> lines) {
      for (final entry in lines.entries) {
        final lineCells = entry.value;
        if (lineCells.every((c) => grid.containsKey(c))) {
          toClear.addAll(lineCells);
        }
      }
    }

    checkAxis(_qLines);
    checkAxis(_rLines);
    checkAxis(_sLines);

    return toClear;
  }

  /// Clear cells from grid.
  static void clearCells(Map<HexCoord, Color> grid, Set<HexCoord> cells) {
    for (final cell in cells) {
      grid.remove(cell);
    }
  }

  /// Count completed lines (for scoring).
  static int countCompletedLines(Map<HexCoord, Color> grid) {
    int lines = 0;
    for (final entry in _qLines.entries) {
      if (entry.value.every((c) => grid.containsKey(c))) lines++;
    }
    for (final entry in _rLines.entries) {
      if (entry.value.every((c) => grid.containsKey(c))) lines++;
    }
    for (final entry in _sLines.entries) {
      if (entry.value.every((c) => grid.containsKey(c))) lines++;
    }
    return lines;
  }

  /// Check if any piece from the given list can fit anywhere.
  static bool canFitAny(
    Map<HexCoord, Color> grid,
    List<List<HexCoord>> pieces,
  ) {
    for (final pieceCells in pieces) {
      for (final boardCell in boardCells) {
        if (canPlace(grid, pieceCells, boardCell)) {
          return true;
        }
      }
    }
    return false;
  }
}
