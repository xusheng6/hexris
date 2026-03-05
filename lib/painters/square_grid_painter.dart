import 'package:flutter/material.dart';
import '../models/coordinates.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class SquareGridPainter extends CustomPainter {
  final List<List<Color?>> grid;
  final Set<dynamic> ghostCells;
  final bool ghostValid;
  final double cellSize;
  final Set<dynamic> cellsToClear;
  final double clearProgress; // 0.0 → 1.0

  SquareGridPainter({
    required this.grid,
    required this.ghostCells,
    required this.ghostValid,
    required this.cellSize,
    this.cellsToClear = const {},
    this.clearProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gap = GameConstants.cellGap;
    final radius = GameConstants.cornerRadius;
    final paint = Paint();

    for (int r = 0; r < GameConstants.squareGridSize; r++) {
      for (int c = 0; c < GameConstants.squareGridSize; c++) {
        final cx = c * cellSize + cellSize / 2;
        final cy = r * cellSize + cellSize / 2;
        final w = cellSize - gap;

        final coord = SquareCoord(r, c);
        final isClearing = cellsToClear.contains(coord);
        final isGhost = ghostCells.contains(coord);

        if (isClearing && grid[r][c] != null) {
          // Animation: flash white at start, then shrink + fade out
          final scale = 1.0 - clearProgress;
          final flashWhite = (1.0 - clearProgress).clamp(0.0, 1.0);
          final cellColor =
              Color.lerp(grid[r][c]!, Colors.white, flashWhite * 0.6)!;
          paint.color = cellColor.withAlpha((255 * scale).round());

          final scaledW = w * scale;
          final rect = RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy), width: scaledW, height: scaledW),
            Radius.circular(radius),
          );
          canvas.drawRRect(rect, paint);
        } else if (grid[r][c] != null) {
          paint.color = grid[r][c]!;
          final rect = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: w, height: w),
            Radius.circular(radius),
          );
          canvas.drawRRect(rect, paint);
        } else if (isGhost) {
          paint.color = ghostValid
              ? Colors.white.withAlpha(60)
              : Colors.red.withAlpha(60);
          final rect = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: w, height: w),
            Radius.circular(radius),
          );
          canvas.drawRRect(rect, paint);
        } else {
          paint.color = GameColors.emptyCell;
          final rect = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: w, height: w),
            Radius.circular(radius),
          );
          canvas.drawRRect(rect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(SquareGridPainter oldDelegate) => true;
}
