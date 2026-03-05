import 'package:flutter/material.dart';
import '../models/coordinates.dart';
import '../models/piece.dart';
import '../painters/piece_painter.dart';
import '../utils/hex_math.dart';
import '../utils/storage.dart';

class DraggablePieceWidget extends StatelessWidget {
  final int trayIndex;
  final TrayPiece piece;
  final GameMode mode;
  final double gridCellSize; // actual cell size on the grid

  const DraggablePieceWidget({
    super.key,
    required this.trayIndex,
    required this.piece,
    required this.mode,
    required this.gridCellSize,
  });

  @override
  Widget build(BuildContext context) {
    if (piece.isPlaced) {
      return const SizedBox(width: 100, height: 100);
    }

    // Tray shows pieces at ~60% of grid size, feedback at full grid size
    final trayScale = mode == GameMode.square
        ? gridCellSize * 0.55
        : gridCellSize * 0.5;
    final feedbackScale = gridCellSize;

    final traySize = _computeSize(trayScale);
    final feedbackSize = _computeSize(feedbackScale);

    // Compute anchor offset: where cell (0,0) is within the feedback widget
    final anchorOffset = mode == GameMode.square
        ? computeSquareAnchorOffset(feedbackScale)
        : computeHexAnchorOffset(
            piece.cells.cast<HexCoord>(), feedbackScale, feedbackSize);

    final child = CustomPaint(
      size: traySize,
      painter: _createPainter(trayScale),
    );

    final feedback = Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: 0.8,
        child: CustomPaint(
          size: feedbackSize,
          painter: _createPainter(feedbackScale),
        ),
      ),
    );

    return Draggable<PieceDragData>(
      data: PieceDragData(
        trayIndex: trayIndex,
        piece: piece,
        anchorOffset: anchorOffset,
      ),
      feedback: feedback,
      // Scale touch position from tray size to feedback size so the
      // same logical spot on the piece stays under the finger.
      dragAnchorStrategy: (draggable, context, position) {
        final RenderBox renderObject =
            context.findRenderObject()! as RenderBox;
        final localTouch = renderObject.globalToLocal(position);
        return Offset(
          localTouch.dx / traySize.width * feedbackSize.width,
          localTouch.dy / traySize.height * feedbackSize.height,
        );
      },
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: child,
      ),
      child: child,
    );
  }

  Size _computeSize(double scale) {
    if (mode == GameMode.square) {
      final cells = piece.cells.cast<SquareCoord>();
      int maxRow = 0, maxCol = 0;
      for (final c in cells) {
        if (c.row > maxRow) maxRow = c.row;
        if (c.col > maxCol) maxCol = c.col;
      }
      return Size((maxCol + 1) * scale, (maxRow + 1) * scale);
    } else {
      // Compute tight bounding box for hex piece
      final cells = piece.cells.cast<HexCoord>();
      double minX = double.infinity, maxX = double.negativeInfinity;
      double minY = double.infinity, maxY = double.negativeInfinity;
      for (final c in cells) {
        final p = hexToPixel(c, scale);
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
      // Add one hex radius of padding on each side
      return Size(maxX - minX + scale * 2, maxY - minY + scale * 2);
    }
  }

  CustomPainter _createPainter(double scale) {
    if (mode == GameMode.square) {
      return SquarePiecePainter(
        cells: piece.cells.cast<SquareCoord>(),
        color: piece.color,
        cellSize: scale,
      );
    } else {
      return HexPiecePainter(
        cells: piece.cells.cast<HexCoord>(),
        color: piece.color,
        hexSize: scale,
      );
    }
  }
}
