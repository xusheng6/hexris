import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../utils/colors.dart';
import '../utils/storage.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mode toggle
              GestureDetector(
                onTap: () {
                  final newMode = state.mode == GameMode.square
                      ? GameMode.hex
                      : GameMode.square;
                  state.switchMode(newMode);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: GameColors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    state.mode == GameMode.square
                        ? Icons.hexagon
                        : Icons.square_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              // Score display
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${state.score}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                  const SizedBox(width: 4),
                  Text(
                    '${state.highScore}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Settings
              GestureDetector(
                onTap: () => _showSettings(context, state),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: GameColors.yellow,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameColors.emptyCell,
        title:
            const Text('How to Play', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Drag pieces from the tray onto the board.\n\n'
              'Fill an entire row, column, or diagonal line to clear it and earn bonus points.\n\n'
              'Clearing multiple lines at once gives a combo bonus.\n\n'
              'The game ends when no remaining piece can fit on the board.\n\n'
              'Tap the icon in the top-left to switch between hex and square modes.',
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context, GameState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameColors.emptyCell,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  secondary:
                      const Icon(Icons.volume_up, color: Colors.white70),
                  title: const Text('Sound',
                      style: TextStyle(color: Colors.white)),
                  value: Storage.soundEnabled,
                  activeTrackColor: GameColors.green,
                  onChanged: (val) {
                    setDialogState(() => Storage.soundEnabled = val);
                  },
                ),
                SwitchListTile(
                  secondary:
                      const Icon(Icons.vibration, color: Colors.white70),
                  title: const Text('Haptics',
                      style: TextStyle(color: Colors.white)),
                  value: Storage.hapticsEnabled,
                  activeTrackColor: GameColors.green,
                  onChanged: (val) {
                    setDialogState(() => Storage.hapticsEnabled = val);
                  },
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.white70),
                  title: const Text('New Game',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    state.reset();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: Colors.white70),
                  title: const Text('Reset High Score',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    state.resetHighScore();
                    Navigator.pop(context);
                  },
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading:
                      const Icon(Icons.help_outline, color: Colors.white70),
                  title: const Text('How to Play',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _showHowToPlay(context);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
