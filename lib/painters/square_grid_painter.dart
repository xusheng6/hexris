import 'package:flutter/material.dart';
import '../models/coordinates.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class SquareGridPainter extends CustomPainter {
  final List<List<Color?>> grid;
  final Set<dynamic> ghostCells;
  final bool ghostValid;
  final double cellSize;

  SquareGridPainter({
    required this.grid,
    required this.ghostCells,
    required this.ghostValid,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gap = GameConstants.cellGap;
    final radius = GameConstants.cornerRadius;
    final paint = Paint();

    for (int r = 0; r < GameConstants.squareGridSize; r++) {
      for (int c = 0; c < GameConstants.squareGridSize; c++) {
        final x = c * cellSize + gap / 2;
        final y = r * cellSize + gap / 2;
        final w = cellSize - gap;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, w),
          Radius.circular(radius),
        );

        final coord = SquareCoord(r, c);
        final isGhost = ghostCells.contains(coord);

        if (grid[r][c] != null) {
          paint.color = grid[r][c]!;
          canvas.drawRRect(rect, paint);
        } else if (isGhost) {
          paint.color = ghostValid
              ? Colors.white.withAlpha(60)
              : Colors.red.withAlpha(60);
          canvas.drawRRect(rect, paint);
        } else {
          paint.color = GameColors.emptyCell;
          canvas.drawRRect(rect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(SquareGridPainter oldDelegate) => true;
}
