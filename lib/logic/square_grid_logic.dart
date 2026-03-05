import 'package:flutter/material.dart';
import '../models/coordinates.dart';
import '../utils/constants.dart';

class SquareGridLogic {
  static const int size = GameConstants.squareGridSize;

  /// Check if piece can be placed at anchor position.
  static bool canPlace(
    List<List<Color?>> grid,
    List<SquareCoord> pieceCells,
    SquareCoord anchor,
  ) {
    for (final cell in pieceCells) {
      final r = anchor.row + cell.row;
      final c = anchor.col + cell.col;
      if (r < 0 || r >= size || c < 0 || c >= size) return false;
      if (grid[r][c] != null) return false;
    }
    return true;
  }

  /// Place piece on grid (mutates grid). Returns placed cell coords.
  static List<SquareCoord> place(
    List<List<Color?>> grid,
    List<SquareCoord> pieceCells,
    SquareCoord anchor,
    Color color,
  ) {
    final placed = <SquareCoord>[];
    for (final cell in pieceCells) {
      final r = anchor.row + cell.row;
      final c = anchor.col + cell.col;
      grid[r][c] = color;
      placed.add(SquareCoord(r, c));
    }
    return placed;
  }

  /// Find all cells on completed rows and columns.
  static Set<SquareCoord> findCompletedLines(List<List<Color?>> grid) {
    final toClear = <SquareCoord>{};

    // Check rows
    for (int r = 0; r < size; r++) {
      bool complete = true;
      for (int c = 0; c < size; c++) {
        if (grid[r][c] == null) {
          complete = false;
          break;
        }
      }
      if (complete) {
        for (int c = 0; c < size; c++) {
          toClear.add(SquareCoord(r, c));
        }
      }
    }

    // Check columns
    for (int c = 0; c < size; c++) {
      bool complete = true;
      for (int r = 0; r < size; r++) {
        if (grid[r][c] == null) {
          complete = false;
          break;
        }
      }
      if (complete) {
        for (int r = 0; r < size; r++) {
          toClear.add(SquareCoord(r, c));
        }
      }
    }

    return toClear;
  }

  /// Clear cells from grid.
  static void clearCells(List<List<Color?>> grid, Set<SquareCoord> cells) {
    for (final cell in cells) {
      grid[cell.row][cell.col] = null;
    }
  }

  /// Count how many complete lines were found (for scoring).
  static int countCompletedLines(List<List<Color?>> grid) {
    int lines = 0;
    for (int r = 0; r < size; r++) {
      if (List.generate(size, (c) => grid[r][c]).every((c) => c != null)) {
        lines++;
      }
    }
    for (int c = 0; c < size; c++) {
      if (List.generate(size, (r) => grid[r][c]).every((c) => c != null)) {
        lines++;
      }
    }
    return lines;
  }

  /// Check if any piece from the given list can fit anywhere on the grid.
  static bool canFitAny(
    List<List<Color?>> grid,
    List<List<SquareCoord>> pieces,
  ) {
    for (final pieceCells in pieces) {
      for (int r = 0; r < size; r++) {
        for (int c = 0; c < size; c++) {
          if (canPlace(grid, pieceCells, SquareCoord(r, c))) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Create empty grid.
  static List<List<Color?>> createEmptyGrid() {
    return List.generate(size, (_) => List.filled(size, null));
  }
}
