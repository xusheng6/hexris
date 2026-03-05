import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/coordinates.dart';
import '../utils/colors.dart';
import '../utils/hex_math.dart';

class HexGridPainter extends CustomPainter {
  final Set<HexCoord> boardCells;
  final Map<HexCoord, Color> grid;
  final Set<dynamic> ghostCells;
  final bool ghostValid;
  final double hexSize;
  final Offset center;
  final Set<dynamic> cellsToClear;
  final double clearProgress; // 0.0 → 1.0

  HexGridPainter({
    required this.boardCells,
    required this.grid,
    required this.ghostCells,
    required this.ghostValid,
    required this.hexSize,
    required this.center,
    this.cellsToClear = const {},
    this.clearProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final inset = 2.0;

    for (final coord in boardCells) {
      final pixel = hexToPixel(coord, hexSize) + center;
      final isClearing = cellsToClear.contains(coord);
      final isGhost = ghostCells.contains(coord);

      if (isClearing && grid.containsKey(coord)) {
        // Animation: flash white at start, then shrink + fade out
        final scale = 1.0 - clearProgress;
        final flashWhite = (1.0 - clearProgress).clamp(0.0, 1.0);
        final cellColor =
            Color.lerp(grid[coord]!, Colors.white, flashWhite * 0.6)!;
        paint.color = cellColor.withAlpha((255 * scale).round());

        final animSize = (hexSize - inset) * scale;
        final vertices = hexVertices(pixel.dx, pixel.dy, animSize);
        final path = ui.Path();
        path.moveTo(vertices[0].dx, vertices[0].dy);
        for (int i = 1; i < 6; i++) {
          path.lineTo(vertices[i].dx, vertices[i].dy);
        }
        path.close();
        canvas.drawPath(path, paint);
      } else if (grid.containsKey(coord)) {
        paint.color = grid[coord]!;
        _drawHex(canvas, paint, pixel, hexSize - inset);
      } else if (isGhost) {
        paint.color = ghostValid
            ? Colors.white.withAlpha(60)
            : Colors.red.withAlpha(60);
        _drawHex(canvas, paint, pixel, hexSize - inset);
      } else {
        paint.color = GameColors.emptyCell;
        _drawHex(canvas, paint, pixel, hexSize - inset);
      }
    }
  }

  void _drawHex(Canvas canvas, Paint paint, Offset pixel, double size) {
    final vertices = hexVertices(pixel.dx, pixel.dy, size);
    final path = ui.Path();
    path.moveTo(vertices[0].dx, vertices[0].dy);
    for (int i = 1; i < 6; i++) {
      path.lineTo(vertices[i].dx, vertices[i].dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(HexGridPainter oldDelegate) => true;
}
