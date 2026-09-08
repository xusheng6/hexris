import 'dart:math';
import 'package:flutter/material.dart';
import 'coordinates.dart';
import '../utils/colors.dart';
import '../utils/hex_math.dart';
import '../utils/storage.dart';

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
  SquarePiece('h4', [
    SquareCoord(0, 0),
    SquareCoord(0, 1),
    SquareCoord(0, 2),
    SquareCoord(0, 3),
  ]),
  SquarePiece('v4', [
    SquareCoord(0, 0),
    SquareCoord(1, 0),
    SquareCoord(2, 0),
    SquareCoord(3, 0),
  ]),
  SquarePiece('h5', [
    SquareCoord(0, 0),
    SquareCoord(0, 1),
    SquareCoord(0, 2),
    SquareCoord(0, 3),
    SquareCoord(0, 4),
  ]),
  SquarePiece('v5', [
    SquareCoord(0, 0),
    SquareCoord(1, 0),
    SquareCoord(2, 0),
    SquareCoord(3, 0),
    SquareCoord(4, 0),
  ]),
  SquarePiece('sq2', [
    SquareCoord(0, 0),
    SquareCoord(0, 1),
    SquareCoord(1, 0),
    SquareCoord(1, 1),
  ]),
  SquarePiece('sq3', [
    SquareCoord(0, 0),
    SquareCoord(0, 1),
    SquareCoord(0, 2),
    SquareCoord(1, 0),
    SquareCoord(1, 1),
    SquareCoord(1, 2),
    SquareCoord(2, 0),
    SquareCoord(2, 1),
    SquareCoord(2, 2),
  ]),
  SquarePiece('lBR', [SquareCoord(0, 0), SquareCoord(1, 0), SquareCoord(1, 1)]),
  SquarePiece('lBL', [SquareCoord(0, 1), SquareCoord(1, 0), SquareCoord(1, 1)]),
  SquarePiece('lTR', [SquareCoord(0, 0), SquareCoord(0, 1), SquareCoord(1, 0)]),
  SquarePiece('lTL', [SquareCoord(0, 0), SquareCoord(0, 1), SquareCoord(1, 1)]),
  SquarePiece('bigL1', [
    SquareCoord(0, 0),
    SquareCoord(1, 0),
    SquareCoord(2, 0),
    SquareCoord(2, 1),
  ]),
  SquarePiece('bigL2', [
    SquareCoord(0, 0),
    SquareCoord(0, 1),
    SquareCoord(0, 2),
    SquareCoord(1, 0),
  ]),
  SquarePiece('bigL3', [
    SquareCoord(0, 0),
    SquareCoord(0, 1),
    SquareCoord(1, 1),
    SquareCoord(2, 1),
  ]),
  SquarePiece('bigL4', [
    SquareCoord(0, 2),
    SquareCoord(1, 0),
    SquareCoord(1, 1),
    SquareCoord(1, 2),
  ]),
  SquarePiece('bigLr1', [
    SquareCoord(0, 1),
    SquareCoord(1, 1),
    SquareCoord(2, 0),
    SquareCoord(2, 1),
  ]),
  SquarePiece('bigLr2', [
    SquareCoord(0, 0),
    SquareCoord(1, 0),
    SquareCoord(1, 1),
    SquareCoord(1, 2),
  ]),
  SquarePiece('bigLr3', [
    SquareCoord(0, 0),
    SquareCoord(0, 1),
    SquareCoord(1, 0),
    SquareCoord(2, 0),
  ]),
  SquarePiece('bigLr4', [
    SquareCoord(0, 0),
    SquareCoord(0, 1),
    SquareCoord(0, 2),
    SquareCoord(1, 2),
  ]),
  SquarePiece('tDown', [
    SquareCoord(0, 0),
    SquareCoord(0, 1),
    SquareCoord(0, 2),
    SquareCoord(1, 1),
  ]),
  SquarePiece('tUp', [
    SquareCoord(0, 1),
    SquareCoord(1, 0),
    SquareCoord(1, 1),
    SquareCoord(1, 2),
  ]),
  SquarePiece('tRight', [
    SquareCoord(0, 0),
    SquareCoord(1, 0),
    SquareCoord(1, 1),
    SquareCoord(2, 0),
  ]),
  SquarePiece('tLeft', [
    SquareCoord(0, 1),
    SquareCoord(1, 0),
    SquareCoord(1, 1),
    SquareCoord(2, 1),
  ]),
  SquarePiece('rect2x3', [
    SquareCoord(0, 0),
    SquareCoord(0, 1),
    SquareCoord(0, 2),
    SquareCoord(1, 0),
    SquareCoord(1, 1),
    SquareCoord(1, 2),
  ]),
  SquarePiece('rect3x2', [
    SquareCoord(0, 0),
    SquareCoord(0, 1),
    SquareCoord(1, 0),
    SquareCoord(1, 1),
    SquareCoord(2, 0),
    SquareCoord(2, 1),
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
  HexPiece('line4_e', [
    HexCoord(0, 0),
    HexCoord(1, 0),
    HexCoord(2, 0),
    HexCoord(3, 0),
  ]),
  HexPiece('line4_se', [
    HexCoord(0, 0),
    HexCoord(0, 1),
    HexCoord(0, 2),
    HexCoord(0, 3),
  ]),
  HexPiece('line4_sw', [
    HexCoord(0, 0),
    HexCoord(-1, 1),
    HexCoord(-2, 2),
    HexCoord(-3, 3),
  ]),
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
  HexPiece('diamond_1', [
    HexCoord(0, 0),
    HexCoord(1, 0),
    HexCoord(0, 1),
    HexCoord(1, 1),
  ]),
  HexPiece('diamond_2', [
    HexCoord(0, 0),
    HexCoord(1, -1),
    HexCoord(0, 1),
    HexCoord(1, 0),
  ]),
  HexPiece('diamond_3', [
    HexCoord(0, 0),
    HexCoord(-1, 1),
    HexCoord(1, 0),
    HexCoord(0, 1),
  ]),
  // Fan shapes
  HexPiece('fan_1', [
    HexCoord(0, 0),
    HexCoord(1, 0),
    HexCoord(0, 1),
    HexCoord(-1, 1),
  ]),
  HexPiece('fan_2', [
    HexCoord(0, 0),
    HexCoord(1, -1),
    HexCoord(1, 0),
    HexCoord(0, 1),
  ]),
  // S/Z zigzag 4-cell
  HexPiece('s_1', [
    HexCoord(0, 0),
    HexCoord(1, 0),
    HexCoord(1, 1),
    HexCoord(2, 1),
  ]),
];

// --- Classic rules catalogs -----------------------------------------------
//
// Recovered from the decrypted ARM64 executable. The original stores square
// pieces as 5x5 ASCII masks and hex pieces as 4x4 masks. Hex masks use an
// even-row offset grid; q = x - floor(y / 2) converts them to our axial grid.

class WeightedSquarePieceFamily {
  final String id;
  final int weight;
  final int originalColorIndex;
  final List<SquarePiece> variants;

  const WeightedSquarePieceFamily({
    required this.id,
    required this.weight,
    required this.originalColorIndex,
    required this.variants,
  });
}

const List<WeightedSquarePieceFamily> classicSquareFamilies = [
  WeightedSquarePieceFamily(
    id: 'line5',
    weight: 2,
    originalColorIndex: 1,
    variants: [
      SquarePiece('line5_h', [
        SquareCoord(0, 0),
        SquareCoord(0, 1),
        SquareCoord(0, 2),
        SquareCoord(0, 3),
        SquareCoord(0, 4),
      ]),
      SquarePiece('line5_v', [
        SquareCoord(0, 0),
        SquareCoord(1, 0),
        SquareCoord(2, 0),
        SquareCoord(3, 0),
        SquareCoord(4, 0),
      ]),
    ],
  ),
  WeightedSquarePieceFamily(
    id: 'line4',
    weight: 2,
    originalColorIndex: 2,
    variants: [
      SquarePiece('line4_v', [
        SquareCoord(0, 0),
        SquareCoord(1, 0),
        SquareCoord(2, 0),
        SquareCoord(3, 0),
      ]),
      SquarePiece('line4_h', [
        SquareCoord(0, 0),
        SquareCoord(0, 1),
        SquareCoord(0, 2),
        SquareCoord(0, 3),
      ]),
    ],
  ),
  WeightedSquarePieceFamily(
    id: 'line3',
    weight: 3,
    originalColorIndex: 3,
    variants: [
      SquarePiece('line3_h', [
        SquareCoord(0, 0),
        SquareCoord(0, 1),
        SquareCoord(0, 2),
      ]),
      SquarePiece('line3_v', [
        SquareCoord(0, 0),
        SquareCoord(1, 0),
        SquareCoord(2, 0),
      ]),
    ],
  ),
  WeightedSquarePieceFamily(
    id: 'line2',
    weight: 3,
    originalColorIndex: 4,
    variants: [
      SquarePiece('line2_v', [SquareCoord(0, 0), SquareCoord(1, 0)]),
      SquarePiece('line2_h', [SquareCoord(0, 0), SquareCoord(0, 1)]),
    ],
  ),
  WeightedSquarePieceFamily(
    id: 'corner5',
    weight: 2,
    originalColorIndex: 9,
    variants: [
      SquarePiece('corner5_br', [
        SquareCoord(0, 0),
        SquareCoord(0, 1),
        SquareCoord(0, 2),
        SquareCoord(1, 2),
        SquareCoord(2, 2),
      ]),
      SquarePiece('corner5_bl', [
        SquareCoord(0, 2),
        SquareCoord(1, 2),
        SquareCoord(2, 0),
        SquareCoord(2, 1),
        SquareCoord(2, 2),
      ]),
      SquarePiece('corner5_tr', [
        SquareCoord(0, 0),
        SquareCoord(1, 0),
        SquareCoord(2, 0),
        SquareCoord(2, 1),
        SquareCoord(2, 2),
      ]),
      SquarePiece('corner5_tl', [
        SquareCoord(0, 0),
        SquareCoord(0, 1),
        SquareCoord(0, 2),
        SquareCoord(1, 0),
        SquareCoord(2, 0),
      ]),
    ],
  ),
  WeightedSquarePieceFamily(
    id: 'corner3',
    weight: 3,
    originalColorIndex: 5,
    variants: [
      SquarePiece('corner3_br', [
        SquareCoord(0, 0),
        SquareCoord(0, 1),
        SquareCoord(1, 0),
      ]),
      SquarePiece('corner3_bl', [
        SquareCoord(0, 0),
        SquareCoord(0, 1),
        SquareCoord(1, 1),
      ]),
      SquarePiece('corner3_tr', [
        SquareCoord(0, 1),
        SquareCoord(1, 0),
        SquareCoord(1, 1),
      ]),
      SquarePiece('corner3_tl', [
        SquareCoord(0, 0),
        SquareCoord(1, 0),
        SquareCoord(1, 1),
      ]),
    ],
  ),
  WeightedSquarePieceFamily(
    id: 'square2',
    weight: 3,
    originalColorIndex: 7,
    variants: [
      SquarePiece('square2', [
        SquareCoord(0, 0),
        SquareCoord(0, 1),
        SquareCoord(1, 0),
        SquareCoord(1, 1),
      ]),
    ],
  ),
  WeightedSquarePieceFamily(
    id: 'square3',
    weight: 1,
    originalColorIndex: 8,
    variants: [
      SquarePiece('square3', [
        SquareCoord(0, 0),
        SquareCoord(0, 1),
        SquareCoord(0, 2),
        SquareCoord(1, 0),
        SquareCoord(1, 1),
        SquareCoord(1, 2),
        SquareCoord(2, 0),
        SquareCoord(2, 1),
        SquareCoord(2, 2),
      ]),
    ],
  ),
  WeightedSquarePieceFamily(
    id: 'dot',
    weight: 1,
    originalColorIndex: 6,
    variants: [
      SquarePiece('dot', [SquareCoord(0, 0)]),
    ],
  ),
];

// The user-facing square mode does not use the weighted family table above.
// It selects uniformly from a progressively unlocked prefix of this recovered
// 31-entry catalog. The order and color indices match the original binary.
const List<String> _classicSquareMasks = [
  '0000000000001000000000000',
  '0000000000011100000000000',
  '0000000100001000010000100',
  '0000000000001100010000000',
  '0000000000001100011000000',
  '0000001110000100001000000',
  '0000000000111110000000000',
  '0000001110011100111000000',
  '0000001000011100000000000',
  '0000000000001000010000000',
  '0000000100011100000000000',
  '0000000000011000000000000',
  '0000000100001000010000000',
  '0000000110011000000000000',
  '0000000000011000010000000',
  '0000000100001100001000000',
  '0000000000111100000000000',
  '0010000100001000010000100',
  '0000001110010000100000000',
  '0000000100001000110000000',
  '0000000100011000010000000',
  '0000000100001100000000000',
  '0000000100011000000000000',
  '0000000010000100111000000',
  '0000001000010000111000000',
  '0000001100001100000000000',
  '0000000010001100010000000',
  '0000000000011100001000000',
  '0000000110001000010000000',
  '0000000000011100010000000',
  '0000000100001100010000000',
];

const List<int> _classicSquareColorIndices = [
  1, 3, 4, 5, 6, 8, 10, 12, 9, 2, 11, 2, 3, 7, 5, 7,
  4, 10, 8, 9, 11, 5, 5, 8, 8, 7, 7, 9, 9, 11, 11,
];

List<SquareCoord> _decodeClassicSquareMask(String mask) {
  final raw = <SquareCoord>[];
  for (var row = 0; row < 5; row++) {
    for (var col = 0; col < 5; col++) {
      if (mask[row * 5 + col] == '1') raw.add(SquareCoord(row, col));
    }
  }
  final minRow = raw.map((cell) => cell.row).reduce(min);
  final minCol = raw.map((cell) => cell.col).reduce(min);
  return raw
      .map((cell) => SquareCoord(cell.row - minRow, cell.col - minCol))
      .toList(growable: false);
}

final List<SquarePiece> classicSquarePieceCatalog = List.generate(
  _classicSquareMasks.length,
  (index) => SquarePiece(
    'classicSquare${index + 1}',
    _decodeClassicSquareMask(_classicSquareMasks[index]),
  ),
  growable: false,
);

int classicSquarePoolSize(int level) =>
    min(8 + max(1, level), classicSquarePieceCatalog.length);

const List<String> _classicHexMasks = [
  '0000010000000000',
  '0010011000100000',
  '0000011001100000',
  '0000011000110000',
  '0100010000100010',
  '0001001000100100',
  '0000000011110000',
  '0010011000010000',
  '0110010001000000',
  '0100011000100000',
  '0010111000000000',
  '0000111001000000',
  '0110010000100000',
  '0010011001000000',
  '0001011000100000',
  '0100111000000000',
  '0000111000100000',
  '0100100001100000',
  '0000011001010000',
  '0110001000100000',
  '0010001001100000',
  '0000101001100000',
];

List<HexCoord> _decodeClassicHexMask(String mask) {
  final cells = <HexCoord>[];
  for (var y = 0; y < 4; y++) {
    for (var x = 0; x < 4; x++) {
      if (mask[y * 4 + x] == '1') {
        cells.add(HexCoord(x - (y ~/ 2), y));
      }
    }
  }
  final origin = cells.first;
  return cells.map((c) => HexCoord(c.q - origin.q, c.r - origin.r)).toList();
}

final List<HexPiece> classicHexPieceCatalog = List.generate(
  _classicHexMasks.length,
  (index) => HexPiece(
    'classicHex${index + 1}',
    _decodeClassicHexMask(_classicHexMasks[index]),
  ),
  growable: false,
);

int classicHexColorIndex(int catalogIndex) {
  if (catalogIndex == 0) return 1;
  if (catalogIndex <= 3) return 2;
  if (catalogIndex <= 6) return 3;
  if (catalogIndex <= 11) return 4;
  if (catalogIndex <= 16) return 5;
  return 6;
}

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

List<TrayPiece> generateSquareTray({
  GameRules rules = GameRules.modern,
  int level = 1,
  Random? random,
}) {
  final rng = random ?? _random;
  return List.generate(3, (_) {
    if (rules == GameRules.classic) {
      final index = rng.nextInt(classicSquarePoolSize(level));
      final piece = classicSquarePieceCatalog[index];
      return TrayPiece(
        cells: piece.cells,
        color: GameColors.classicColor(_classicSquareColorIndices[index]),
      );
    }
    final piece = squarePieceCatalog[rng.nextInt(squarePieceCatalog.length)];
    final color =
        GameColors.pieceColors[rng.nextInt(GameColors.pieceColors.length)];
    return TrayPiece(cells: piece.cells, color: color);
  });
}

List<TrayPiece> generateHexTray({
  GameRules rules = GameRules.modern,
  Random? random,
}) {
  final rng = random ?? _random;
  return List.generate(3, (_) {
    if (rules == GameRules.classic) {
      final index = rng.nextInt(classicHexPieceCatalog.length);
      final piece = classicHexPieceCatalog[index];
      return TrayPiece(
        cells: piece.cells,
        color: GameColors.classicColor(classicHexColorIndex(index)),
      );
    }
    final piece = hexPieceCatalog[rng.nextInt(hexPieceCatalog.length)];
    final color =
        GameColors.pieceColors[rng.nextInt(GameColors.pieceColors.length)];
    return TrayPiece(cells: piece.cells, color: color);
  });
}

/// Compute the pixel position of cell (0,0) within a hex piece feedback widget.
Offset computeHexAnchorOffset(
  List<HexCoord> cells,
  double hexSize,
  Size widgetSize,
) {
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
