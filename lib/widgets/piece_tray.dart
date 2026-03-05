import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../utils/storage.dart';
import 'draggable_piece.dart';

class PieceTray extends StatelessWidget {
  final double gridCellSize;

  const PieceTray({super.key, required this.gridCellSize});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, _) {
        return SizedBox(
          height: state.mode == GameMode.square ? 160 : 160,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              return DraggablePieceWidget(
                trayIndex: index,
                piece: state.tray[index],
                mode: state.mode,
                gridCellSize: gridCellSize,
              );
            }),
          ),
        );
      },
    );
  }
}
