enum GameMode { square, hex }

class Storage {
  static final Map<String, int> _cache = {};

  static Future<int> loadHighScore(GameMode mode) async {
    return _cache['highScore_${mode.name}'] ?? 0;
  }

  static Future<void> saveHighScore(GameMode mode, int score) async {
    _cache['highScore_${mode.name}'] = score;
  }
}
