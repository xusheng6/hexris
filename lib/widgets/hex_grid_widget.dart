import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/coordinates.dart';
import '../models/piece.dart';
import '../logic/hex_grid_logic.dart';
import '../painters/hex_grid_painter.dart';
import '../utils/hex_math.dart';
import 'dart:math' as math;

class HexGridWidget extends StatelessWidget {
  const HexGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = math.min(constraints.maxWidth, constraints.maxHeight);
        // Compute hex size to fit the board (9 hexes wide for radius 5)
        // Pointy-top: width of hex grid = sqrt(3) * size * (2*radius - 1)
        final hexSize = maxSize / (math.sqrt(3) * 9 + 1);
        final center = Offset(maxSize / 2, maxSize / 2);

        return Consumer<GameState>(
          builder: (context, state, _) {
            return DragTarget<PieceDragData>(
              onWillAcceptWithDetails: (details) => true,
              onMove: (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                final local = renderBox.globalToLocal(details.offset);
                // Adjust by anchorOffset so cursor maps to cell (0,0)
                final adjusted = local + details.data.anchorOffset;
                _updateGhost(state, adjusted, details.data.piece, hexSize, center);
              },
              onLeave: (_) => state.clearGhost(),
              onAcceptWithDetails: (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                final local = renderBox.globalToLocal(details.offset);
                final adjusted = local + details.data.anchorOffset;
                final anchor = _pixelToHexCoord(adjusted, hexSize, center);
                if (anchor != null) {
                  state.placePiece(details.data.trayIndex, anchor);
                }
              },
              builder: (context, candidateData, rejectedData) {
                return CustomPaint(
                  size: Size(maxSize, maxSize),
                  painter: HexGridPainter(
                    boardCells: HexGridLogic.boardCells,
                    grid: state.hexGrid,
                    ghostCells: state.ghostCells,
                    ghostValid: state.ghostValid,
                    hexSize: hexSize,
                    center: center,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _updateGhost(GameState state, Offset local, TrayPiece piece,
      double hexSize, Offset center) {
    final anchor = _pixelToHexCoord(local, hexSize, center);
    if (anchor == null) {
      state.clearGhost();
      return;
    }
    final cells = piece.cells.cast<HexCoord>();
    final ghostCoords = <HexCoord>{};
    bool allValid = true;
    for (final c in cells) {
      final pos = anchor + c;
      ghostCoords.add(pos);
      if (!HexGridLogic.boardCells.contains(pos) ||
          state.hexGrid.containsKey(pos)) {
        allValid = false;
      }
    }
    state.updateGhost(ghostCoords, allValid);
  }

  HexCoord? _pixelToHexCoord(Offset local, double hexSize, Offset center) {
    final relative = local - center;
    final hex = pixelToHex(relative, hexSize);
    if (!HexGridLogic.boardCells.contains(hex)) return null;
    return hex;
  }
}
