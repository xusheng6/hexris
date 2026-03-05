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

  final highScore = await Storage.loadHighScore(GameMode.hex);

  runApp(HexrisApp(initialHighScore: highScore));
}

class HexrisApp extends StatelessWidget {
  final int initialHighScore;

  const HexrisApp({super.key, required this.initialHighScore});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState(initialHighScore: initialHighScore),
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
