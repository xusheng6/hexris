import 'package:shared_preferences/shared_preferences.dart';

enum GameMode { square, hex }

class Storage {
  static SharedPreferences? _prefs;

  /// Must be called once before any other access (e.g. in main()).
  /// Loads the persistent store from disk so subsequent reads are synchronous.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<int> loadHighScore(GameMode mode) async {
    await init();
    return _prefs!.getInt('highScore_${mode.name}') ?? 0;
  }

  static Future<DateTime?> loadHighScoreDate(GameMode mode) async {
    await init();
    final raw = _prefs!.getString('highScoreDate_${mode.name}');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<void> saveHighScore(
      GameMode mode, int score, DateTime date) async {
    await init();
    await _prefs!.setInt('highScore_${mode.name}', score);
    await _prefs!
        .setString('highScoreDate_${mode.name}', date.toIso8601String());
  }

  static Future<void> clearHighScore(GameMode mode) async {
    await init();
    await _prefs!.remove('highScore_${mode.name}');
    await _prefs!.remove('highScoreDate_${mode.name}');
  }

  // Settings (persisted, default ON). Reads fall back to true until init().
  static bool get soundEnabled => _prefs?.getBool('soundEnabled') ?? true;
  static set soundEnabled(bool value) => _prefs?.setBool('soundEnabled', value);

  static bool get hapticsEnabled => _prefs?.getBool('hapticsEnabled') ?? true;
  static set hapticsEnabled(bool value) =>
      _prefs?.setBool('hapticsEnabled', value);
}
