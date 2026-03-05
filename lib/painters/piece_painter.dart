import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/coordinates.dart';
import '../utils/constants.dart';
import '../utils/hex_math.dart';

class SquarePiecePainter extends CustomPainter {
  final List<SquareCoord> cells;
  final Color color;
  final double cellSize;

  SquarePiecePainter({
    required this.cells,
    required this.color,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final gap = GameConstants.cellGap;
    final radius = GameConstants.cornerRadius;

    for (final cell in cells) {
      final x = cell.col * cellSize + gap / 2;
      final y = cell.row * cellSize + gap / 2;
      final w = cellSize - gap;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, w),
          Radius.circular(radius),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SquarePiecePainter oldDelegate) => true;
}

class HexPiecePainter extends CustomPainter {
  final List<HexCoord> cells;
  final Color color;
  final double hexSize;

  HexPiecePainter({
    required this.cells,
    required this.color,
    required this.hexSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final inset = 2.0;

    // Find center offset so piece is centered in its bounding box
    final center = Offset(size.width / 2, size.height / 2);

    // Compute average pixel position of all cells to center the piece
    double avgX = 0, avgY = 0;
    for (final cell in cells) {
      final p = hexToPixel(cell, hexSize);
      avgX += p.dx;
      avgY += p.dy;
    }
    avgX /= cells.length;
    avgY /= cells.length;
    final offset = center - Offset(avgX, avgY);

    for (final cell in cells) {
      final pixel = hexToPixel(cell, hexSize) + offset;
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
  bool shouldRepaint(HexPiecePainter oldDelegate) => true;
}
