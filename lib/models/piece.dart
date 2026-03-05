import 'dart:math';
import 'package:flutter/material.dart';
import 'coordinates.dart';
import '../utils/colors.dart';
import '../utils/hex_math.dart';

// --- Square Pieces ---

class SquarePiece {
  final String id;
  final List<SquareCoord> cells;

  const SquarePiece(this.id, this.cells);
}

// All square piece shapes (each rotation is a separate entry)
final List<SquarePiece> squarePieceCatalog = [
  SquarePiece('dot', [SquareCoord(0, 0)]),
  SquarePiece('h2', [SquareCoord(0, 0), SquareCoord(0, 1)]),
  SquarePiece('v2', [SquareCoord(0, 0), SquareCoord(1, 0)]),
  SquarePiece('h3', [SquareCoord(0, 0), SquareCoord(0, 1), SquareCoord(0, 2)]),
  SquarePiece('v3', [SquareCoord(0, 0), SquareCoord(1, 0), SquareCoord(2, 0)]),
  SquarePiece('h4', [SquareCoord(0, 0), SquareCoord(0, 1), SquareCoord(0, 2), SquareCoord(0, 3)]),
  SquarePiece('v4', [SquareCoord(0, 0), SquareCoord(1, 0), SquareCoord(2, 0), SquareCoord(3, 0)]),
  SquarePiece('h5', [SquareCoord(0, 0), SquareCoord(0, 1), SquareCoord(0, 2), SquareCoord(0, 3), SquareCoord(0, 4)]),
  SquarePiece('v5', [SquareCoord(0, 0), SquareCoord(1, 0), SquareCoord(2, 0), SquareCoord(3, 0), SquareCoord(4, 0)]),
  SquarePiece('sq2', [SquareCoord(0, 0), SquareCoord(0, 1), SquareCoord(1, 0), SquareCoord(1, 1)]),
  SquarePiece('sq3', [
    SquareCoord(0, 0), SquareCoord(0, 1), SquareCoord(0, 2),
    SquareCoord(1, 0), SquareCoord(1, 1), SquareCoord(1, 2),
    SquareCoord(2, 0), SquareCoord(2, 1), SquareCoord(2, 2),
  ]),
  SquarePiece('lBR', [SquareCoord(0, 0), SquareCoord(1, 0), SquareCoord(1, 1)]),
  SquarePiece('lBL', [SquareCoord(0, 1), SquareCoord(1, 0), SquareCoord(1, 1)]),
  SquarePiece('lTR', [SquareCoord(0, 0), SquareCoord(0, 1), SquareCoord(1, 0)]),
  SquarePiece('lTL', [SquareCoord(0, 0), SquareCoord(0, 1), SquareCoord(1, 1)]),
  SquarePiece('bigL1', [SquareCoord(0, 0), SquareCoord(1, 0), SquareCoord(2, 0), SquareCoord(2, 1)]),
  SquarePiece('bigL2', [SquareCoord(0, 0), SquareCoord(0, 1), SquareCoord(0, 2), SquareCoord(1, 0)]),
  SquarePiece('bigL3', [SquareCoord(0, 0), SquareCoord(0, 1), SquareCoord(1, 1), SquareCoord(2, 1)]),
  SquarePiece('bigL4', [SquareCoord(0, 2), SquareCoord(1, 0), SquareCoord(1, 1), SquareCoord(1, 2)]),
  SquarePiece('bigLr1', [SquareCoord(0, 1), SquareCoord(1, 1), SquareCoord(2, 0), SquareCoord(2, 1)]),
  SquarePiece('bigLr2', [SquareCoord(0, 0), SquareCoord(1, 0), SquareCoord(1, 1), SquareCoord(1, 2)]),
  SquarePiece('bigLr3', [SquareCoord(0, 0), SquareCoord(0, 1), SquareCoord(1, 0), SquareCoord(2, 0)]),
  SquarePiece('bigLr4', [SquareCoord(0, 0), SquareCoord(0, 1), SquareCoord(0, 2), SquareCoord(1, 2)]),
  SquarePiece('tDown', [SquareCoord(0, 0), SquareCoord(0, 1), SquareCoord(0, 2), SquareCoord(1, 1)]),
  SquarePiece('tUp', [SquareCoord(0, 1), SquareCoord(1, 0), SquareCoord(1, 1), SquareCoord(1, 2)]),
  SquarePiece('tRight', [SquareCoord(0, 0), SquareCoord(1, 0), SquareCoord(1, 1), SquareCoord(2, 0)]),
  SquarePiece('tLeft', [SquareCoord(0, 1), SquareCoord(1, 0), SquareCoord(1, 1), SquareCoord(2, 1)]),
  SquarePiece('rect2x3', [
    SquareCoord(0, 0), SquareCoord(0, 1), SquareCoord(0, 2),
    SquareCoord(1, 0), SquareCoord(1, 1), SquareCoord(1, 2),
  ]),
  SquarePiece('rect3x2', [
    SquareCoord(0, 0), SquareCoord(0, 1),
    SquareCoord(1, 0), SquareCoord(1, 1),
    SquareCoord(2, 0), SquareCoord(2, 1),
  ]),
];

// --- Hex Pieces ---

class HexPiece {
  final String id;
  final List<HexCoord> cells;

  const HexPiece(this.id, this.cells);
}

final List<HexPiece> hexPieceCatalog = [
  // 1-cell
  HexPiece('dot', [HexCoord(0, 0)]),
  // 2-cell lines (3 directions)
  HexPiece('line2_e', [HexCoord(0, 0), HexCoord(1, 0)]),
  HexPiece('line2_se', [HexCoord(0, 0), HexCoord(0, 1)]),
  HexPiece('line2_sw', [HexCoord(0, 0), HexCoord(-1, 1)]),
  // 3-cell lines (3 directions)
  HexPiece('line3_e', [HexCoord(0, 0), HexCoord(1, 0), HexCoord(2, 0)]),
  HexPiece('line3_se', [HexCoord(0, 0), HexCoord(0, 1), HexCoord(0, 2)]),
  HexPiece('line3_sw', [HexCoord(0, 0), HexCoord(-1, 1), HexCoord(-2, 2)]),
  // 4-cell lines (3 directions)
  HexPiece('line4_e', [HexCoord(0, 0), HexCoord(1, 0), HexCoord(2, 0), HexCoord(3, 0)]),
  HexPiece('line4_se', [HexCoord(0, 0), HexCoord(0, 1), HexCoord(0, 2), HexCoord(0, 3)]),
  HexPiece('line4_sw', [HexCoord(0, 0), HexCoord(-1, 1), HexCoord(-2, 2), HexCoord(-3, 3)]),
  // Triangles (2 orientations)
  HexPiece('triDown', [HexCoord(0, 0), HexCoord(1, 0), HexCoord(0, 1)]),
  HexPiece('triUp', [HexCoord(0, 0), HexCoord(1, -1), HexCoord(1, 0)]),
  // V-shapes (6 orientations)
  HexPiece('v1', [HexCoord(-1, 0), HexCoord(0, 0), HexCoord(0, 1)]),
  HexPiece('v2', [HexCoord(0, 0), HexCoord(0, 1), HexCoord(1, 0)]),
  HexPiece('v3', [HexCoord(0, 0), HexCoord(1, -1), HexCoord(0, 1)]),
  HexPiece('v4', [HexCoord(0, 0), HexCoord(1, 0), HexCoord(-1, 1)]),
  HexPiece('v5', [HexCoord(0, -1), HexCoord(0, 0), HexCoord(1, 0)]),
  HexPiece('v6', [HexCoord(0, 0), HexCoord(-1, 1), HexCoord(1, 0)]),
  // Zigzag 3-cell
  HexPiece('zigzag1', [HexCoord(0, 0), HexCoord(1, 0), HexCoord(1, 1)]),
  HexPiece('zigzag2', [HexCoord(0, 0), HexCoord(0, 1), HexCoord(1, 1)]),
  HexPiece('zigzag3', [HexCoord(0, 0), HexCoord(-1, 1), HexCoord(-1, 2)]),
  // === 4-cell pieces ===
  // Diamond / parallelogram
  HexPiece('diamond_1', [HexCoord(0, 0), HexCoord(1, 0), HexCoord(0, 1), HexCoord(1, 1)]),
  HexPiece('diamond_2', [HexCoord(0, 0), HexCoord(1, -1), HexCoord(0, 1), HexCoord(1, 0)]),
  HexPiece('diamond_3', [HexCoord(0, 0), HexCoord(-1, 1), HexCoord(1, 0), HexCoord(0, 1)]),
  // Fan shapes
  HexPiece('fan_1', [HexCoord(0, 0), HexCoord(1, 0), HexCoord(0, 1), HexCoord(-1, 1)]),
  HexPiece('fan_2', [HexCoord(0, 0), HexCoord(1, -1), HexCoord(1, 0), HexCoord(0, 1)]),
  HexPiece('fan_3', [HexCoord(0, 0), HexCoord(-1, 0), HexCoord(0, 1), HexCoord(1, 0)]),
  HexPiece('fan_4', [HexCoord(-1, 0), HexCoord(0, 0), HexCoord(1, 0), HexCoord(0, -1)]),
  HexPiece('fan_5', [HexCoord(0, 0), HexCoord(0, -1), HexCoord(-1, 1), HexCoord(1, 0)]),
  HexPiece('fan_6', [HexCoord(0, 0), HexCoord(-1, 1), HexCoord(0, 1), HexCoord(1, -1)]),
  // L-shapes / bends
  HexPiece('bend_1', [HexCoord(0, 0), HexCoord(1, 0), HexCoord(2, 0), HexCoord(2, 1)]),
  HexPiece('bend_2', [HexCoord(0, 0), HexCoord(0, 1), HexCoord(0, 2), HexCoord(1, 2)]),
  HexPiece('bend_3', [HexCoord(0, 0), HexCoord(-1, 1), HexCoord(-2, 2), HexCoord(-1, 2)]),
  HexPiece('bend_4', [HexCoord(0, 0), HexCoord(0, 1), HexCoord(0, 2), HexCoord(-1, 3)]),
  HexPiece('bend_5', [HexCoord(0, 0), HexCoord(1, 0), HexCoord(2, 0), HexCoord(1, 1)]),
  HexPiece('bend_6', [HexCoord(0, 0), HexCoord(-1, 1), HexCoord(-2, 2), HexCoord(-2, 3)]),
  // Y-shapes
  HexPiece('y_1', [HexCoord(0, 0), HexCoord(1, -1), HexCoord(-1, 1), HexCoord(0, 1)]),
  HexPiece('y_2', [HexCoord(0, 0), HexCoord(1, 0), HexCoord(-1, 0), HexCoord(0, 1)]),
  // S/Z zigzag 4-cell
  HexPiece('s_1', [HexCoord(0, 0), HexCoord(1, 0), HexCoord(1, 1), HexCoord(2, 1)]),
  HexPiece('s_2', [HexCoord(0, 0), HexCoord(0, 1), HexCoord(1, 1), HexCoord(1, 2)]),
  HexPiece('s_3', [HexCoord(0, 0), HexCoord(-1, 1), HexCoord(-1, 2), HexCoord(-2, 3)]),
];

// --- Drag data ---

class PieceDragData {
  final int trayIndex;
  final TrayPiece piece;
  /// Position of anchor cell (0,0) within the feedback widget, in pixels.
  final Offset anchorOffset;

  PieceDragData({
    required this.trayIndex,
    required this.piece,
    required this.anchorOffset,
  });
}

// --- Tray piece (piece + color, placed flag) ---

class TrayPiece {
  final List<dynamic> cells; // SquareCoord or HexCoord offsets
  final Color color;
  bool isPlaced;

  TrayPiece({required this.cells, required this.color, this.isPlaced = false});
}

// --- Piece generation ---

final _random = Random();

List<TrayPiece> generateSquareTray() {
  return List.generate(3, (_) {
    final piece = squarePieceCatalog[_random.nextInt(squarePieceCatalog.length)];
    final color = GameColors.pieceColors[_random.nextInt(GameColors.pieceColors.length)];
    return TrayPiece(cells: piece.cells, color: color);
  });
}

List<TrayPiece> generateHexTray() {
  return List.generate(3, (_) {
    final piece = hexPieceCatalog[_random.nextInt(hexPieceCatalog.length)];
    final color = GameColors.pieceColors[_random.nextInt(GameColors.pieceColors.length)];
    return TrayPiece(cells: piece.cells, color: color);
  });
}

/// Compute the pixel position of cell (0,0) within a hex piece feedback widget.
Offset computeHexAnchorOffset(List<HexCoord> cells, double hexSize, Size widgetSize) {
  // The painter centers the piece: offset = center - Offset(avgX, avgY)
  // Cell (0,0) is drawn at hexToPixel((0,0)) + offset = Offset(0,0) + center - avg
  double avgX = 0, avgY = 0;
  for (final cell in cells) {
    final p = hexToPixel(cell, hexSize);
    avgX += p.dx;
    avgY += p.dy;
  }
  avgX /= cells.length;
  avgY /= cells.length;
  return Offset(widgetSize.width / 2 - avgX, widgetSize.height / 2 - avgY);
}

/// Compute the pixel position of cell (0,0) within a square piece feedback widget.
Offset computeSquareAnchorOffset(double cellSize) {
  // Cell (0,0) is drawn at (gap/2, gap/2) — essentially the top-left
  return Offset(cellSize / 2, cellSize / 2);
}
