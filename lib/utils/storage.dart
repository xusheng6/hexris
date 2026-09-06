import 'package:shared_preferences/shared_preferences.dart';

enum GameMode { square, hex }

enum GameRules { modern, classic }

class Storage {
  static SharedPreferences? _prefs;

  /// Must be called once before any other access (e.g. in main()).
  /// Loads the persistent store from disk so subsequent reads are synchronous.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static String _highScoreKey(GameMode mode, GameRules rules) =>
      rules == GameRules.modern
      ? 'highScore_${mode.name}'
      : 'highScore_${mode.name}_${rules.name}';

  static String _highScoreDateKey(GameMode mode, GameRules rules) =>
      rules == GameRules.modern
      ? 'highScoreDate_${mode.name}'
      : 'highScoreDate_${mode.name}_${rules.name}';

  static Future<int> loadHighScore(
    GameMode mode, {
    GameRules rules = GameRules.modern,
  }) async {
    await init();
    return _prefs!.getInt(_highScoreKey(mode, rules)) ?? 0;
  }

  static Future<DateTime?> loadHighScoreDate(
    GameMode mode, {
    GameRules rules = GameRules.modern,
  }) async {
    await init();
    final raw = _prefs!.getString(_highScoreDateKey(mode, rules));
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<void> saveHighScore(
    GameMode mode,
    int score,
    DateTime date, {
    GameRules rules = GameRules.modern,
  }) async {
    await init();
    await _prefs!.setInt(_highScoreKey(mode, rules), score);
    await _prefs!.setString(
      _highScoreDateKey(mode, rules),
      date.toIso8601String(),
    );
  }

  static Future<void> clearHighScore(
    GameMode mode, {
    GameRules rules = GameRules.modern,
  }) async {
    await init();
    await _prefs!.remove(_highScoreKey(mode, rules));
    await _prefs!.remove(_highScoreDateKey(mode, rules));
  }

  // In-progress game snapshot (serialized as a JSON string).
  static const String _savedGameKey = 'savedGame';

  /// Persist the current game so it survives an app quit. [json] is the
  /// encoded snapshot produced by [GameState.toJson].
  static Future<void> saveGame(String json) async {
    await init();
    await _prefs!.setString(_savedGameKey, json);
  }

  /// The raw saved-game JSON, or null if there is no saved game. Requires
  /// [init] to have completed (call it in main() before use).
  static String? loadSavedGame() => _prefs?.getString(_savedGameKey);

  static Future<void> clearSavedGame() async {
    await init();
    await _prefs!.remove(_savedGameKey);
  }

  // Settings (persisted, default ON). Reads fall back to true until init().
  static bool get soundEnabled => _prefs?.getBool('soundEnabled') ?? true;
  static set soundEnabled(bool value) => _prefs?.setBool('soundEnabled', value);

  static bool get hapticsEnabled => _prefs?.getBool('hapticsEnabled') ?? true;
  static set hapticsEnabled(bool value) =>
      _prefs?.setBool('hapticsEnabled', value);

  static bool get classicRulesEnabled =>
      _prefs?.getBool('classicRulesEnabled') ?? false;
  static set classicRulesEnabled(bool value) =>
      _prefs?.setBool('classicRulesEnabled', value);
}
