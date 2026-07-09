import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'utils/colors.dart';
import 'utils/storage.dart';
import 'widgets/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Storage.init();

  // Restore an in-progress game if one was saved.
  Map<String, dynamic>? savedState;
  final savedRaw = Storage.loadSavedGame();
  if (savedRaw != null) {
    try {
      savedState = jsonDecode(savedRaw) as Map<String, dynamic>;
    } catch (_) {
      savedState = null;
    }
  }

  // High score is stored per mode, so load it for the resumed game's mode.
  final mode = savedState != null
      ? GameMode.values.firstWhere(
          (m) => m.name == savedState!['mode'],
          orElse: () => GameMode.hex,
        )
      : GameMode.hex;
  final highScore = await Storage.loadHighScore(mode);
  final highScoreDate = await Storage.loadHighScoreDate(mode);

  runApp(HexrisApp(
    initialHighScore: highScore,
    initialHighScoreDate: highScoreDate,
    savedState: savedState,
  ));
}

class HexrisApp extends StatefulWidget {
  final int initialHighScore;
  final DateTime? initialHighScoreDate;
  final Map<String, dynamic>? savedState;

  const HexrisApp({
    super.key,
    required this.initialHighScore,
    this.initialHighScoreDate,
    this.savedState,
  });

  @override
  State<HexrisApp> createState() => _HexrisAppState();
}

class _HexrisAppState extends State<HexrisApp> with WidgetsBindingObserver {
  late final GameState _gameState;

  @override
  void initState() {
    super.initState();
    _gameState = GameState(
      initialHighScore: widget.initialHighScore,
      initialHighScoreDate: widget.initialHighScoreDate,
      savedState: widget.savedState,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Flush the current game to disk when the app is backgrounded or closing,
    // in addition to the per-move saves, so nothing is lost on a hard exit.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _gameState.save();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _gameState,
      child: MaterialApp(
        title: 'Hexris',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: GameColors.background,
        ),
        home: const GameScreen(),
      ),
    );
  }
}
