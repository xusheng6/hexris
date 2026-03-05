import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/storage.dart';
import 'header_bar.dart';
import 'square_grid_widget.dart';
import 'hex_grid_widget.dart';
import 'piece_tray.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      body: SafeArea(
        child: Consumer<GameState>(
          builder: (context, state, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                // Compute grid cell size based on available space
                // Reserve ~250 for header + tray + padding
                final availableHeight = constraints.maxHeight - 250;
                final availableWidth = constraints.maxWidth - 32;
                final gridMax = math.min(availableWidth, availableHeight);
                final cellSize = state.mode == GameMode.square
                    ? gridMax / GameConstants.squareGridSize
                    : gridMax / (math.sqrt(3) * 9 + 1);

                return Stack(
                  children: [
                    Column(
                      children: [
                        const HeaderBar(),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: state.mode == GameMode.square
                                  ? const SquareGridWidget()
                                  : const HexGridWidget(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        PieceTray(gridCellSize: cellSize),
                        const SizedBox(height: 16),
                      ],
                    ),
                    // Undo button - bottom left
                    if (state.canUndo)
                      Positioned(
                        left: 16,
                        bottom: 24,
                        child: GestureDetector(
                          onTap: () => state.undo(),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: GameColors.emptyCell,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.undo,
                              color: Colors.white70,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    if (state.isGameOver) _buildGameOverOverlay(context, state),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context, GameState state) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: GameColors.emptyCell,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Game Over',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Score: ${state.score}',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Best: ${state.highScore}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameColors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => state.reset(),
                child: const Text(
                  'Play Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
