import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

class FeedbackManager {
  static final AudioPlayer _player = AudioPlayer();
  
  static Future<void> playSound(String sound) async {
    await _player.stop();
    await _player.play(AssetSource('sounds/$sound.wav'));
  }

  static void triggerHaptic(String event) {
    switch (event) {
      case 'dice':
        HapticFeedback.lightImpact();
        break;
      case 'move':
        HapticFeedback.selectionClick();
        break;
      case 'kill':
        Vibration.vibrate(duration: 200);
        break;
      case 'win':
        Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 500]);
        break;
    }
  }

  static void playDice() {
    playSound('dice_roll');
    triggerHaptic('dice');
  }

  static void playMove() {
    playSound('token_move');
    triggerHaptic('move');
  }

  static void playKill() {
    playSound('kill');
    triggerHaptic('kill');
  }

  static void playWin() {
    playSound('win');
    triggerHaptic('win');
  }
}
