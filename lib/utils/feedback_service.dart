import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'storage.dart';

enum GameSound { place, clear, combo, gameOver }

class FeedbackService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> _playSound(GameSound sound) async {
    if (!Storage.soundEnabled) return;
    final String asset;
    switch (sound) {
      case GameSound.place:
        asset = 'sounds/place.wav';
      case GameSound.clear:
        asset = 'sounds/clear.wav';
      case GameSound.combo:
        asset = 'sounds/combo.wav';
      case GameSound.gameOver:
        asset = 'sounds/gameover.wav';
    }
    await _player.play(AssetSource(asset));
  }

  static void _haptic(GameSound sound) {
    if (!Storage.hapticsEnabled) return;
    switch (sound) {
      case GameSound.place:
        HapticFeedback.lightImpact();
      case GameSound.clear:
        HapticFeedback.mediumImpact();
      case GameSound.combo:
        HapticFeedback.heavyImpact();
      case GameSound.gameOver:
        HapticFeedback.vibrate();
    }
  }

  static void trigger(GameSound sound) {
    _playSound(sound);
    _haptic(sound);
  }
}
