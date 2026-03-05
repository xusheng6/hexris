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

  HexGridPainter({
    required this.boardCells,
    required this.grid,
    required this.ghostCells,
    required this.ghostValid,
    required this.hexSize,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final inset = 2.0; // gap between hexes

    for (final coord in boardCells) {
      final pixel = hexToPixel(coord, hexSize) + center;
      final isGhost = ghostCells.contains(coord);

      if (grid.containsKey(coord)) {
        paint.color = grid[coord]!;
      } else if (isGhost) {
        paint.color = ghostValid
            ? Colors.white.withAlpha(60)
            : Colors.red.withAlpha(60);
      } else {
        paint.color = GameColors.emptyCell;
      }

      final vertices = hexVertices(pixel.dx, pixel.dy, hexSize - inset);
      final path = ui.Path();
      path.moveTo(vertices[0].dx, vertices[0].dy);
      for (int i = 1; i < 6; i++) {
        path.lineTo(vertices[i].dx, vertices[i].dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(HexGridPainter oldDelegate) => true;
}
