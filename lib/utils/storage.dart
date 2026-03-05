enum GameMode { square, hex }

class Storage {
  static final Map<String, int> _cache = {};

  static Future<int> loadHighScore(GameMode mode) async {
    return _cache['highScore_${mode.name}'] ?? 0;
  }

  static Future<void> saveHighScore(GameMode mode, int score) async {
    _cache['highScore_${mode.name}'] = score;
  }

  // Settings (in-memory, default ON)
  static bool get soundEnabled => (_cache['soundEnabled'] ?? 1) == 1;
  static set soundEnabled(bool value) =>
      _cache['soundEnabled'] = value ? 1 : 0;

  static bool get hapticsEnabled => (_cache['hapticsEnabled'] ?? 1) == 1;
  static set hapticsEnabled(bool value) =>
      _cache['hapticsEnabled'] = value ? 1 : 0;
}
