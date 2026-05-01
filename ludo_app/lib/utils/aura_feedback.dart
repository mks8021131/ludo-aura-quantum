import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

class AuraFeedback {
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static final AudioPlayer _layerPlayer = AudioPlayer();
  static final AudioPlayer _ambientPlayer = AudioPlayer();
  static bool vibrationEnabled = true;
  static bool soundEnabled = true;
  static bool diceSoundEnabled = true;
  static bool _ambientStarted = false;
  static DateTime _lastTouch = DateTime.fromMillisecondsSinceEpoch(0);

  static void init(bool vib, bool snd, {bool diceSnd = true}) {
    vibrationEnabled = vib;
    soundEnabled = snd;
    diceSoundEnabled = diceSnd;
    if (soundEnabled) {
      _startAmbient();
    } else {
      _ambientPlayer.stop();
      _ambientStarted = false;
    }
  }

  static Future<void> _startAmbient() async {
    if (_ambientStarted) return;
    _ambientStarted = true;
    try {
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(0.035);
      await _ambientPlayer.play(AssetSource('sounds/ambient.wav'));
    } catch (_) {
      _ambientStarted = false;
    }
  }

  static Future<void> _playSound(String name, {double volume = 0.32, bool layered = false, bool isDice = false}) async {
    if (!soundEnabled) return;
    if (isDice && !diceSoundEnabled) return;
    
    final player = layered ? _layerPlayer : _sfxPlayer;
    try {
      await player.stop();
      await player.setVolume(volume);
      await player.play(AssetSource('sounds/$name'));
    } catch (e) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  static void playQuantumWarp() {
    if (vibrationEnabled) HapticFeedback.heavyImpact();
    _playSound('ui_click.wav', volume: 0.20);
  }

  static void playDiceRoll() {
    if (vibrationEnabled) HapticFeedback.lightImpact();
    _playSound('dice_roll.wav', volume: 0.30, isDice: true);
  }

  static void playDiceResult({bool isSix = false}) {
    if (vibrationEnabled) {
      if (isSix) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }
    _playSound('dice_impact.wav', volume: isSix ? 0.38 : 0.34, layered: true, isDice: true);
  }

  static void playMove() {
    if (vibrationEnabled) HapticFeedback.selectionClick();
    _playSound('move.wav', volume: 0.24);
  }

  static void playUIClick() {
    _playSound('ui_click.wav', volume: 0.16, layered: true);
  }

  static void playTouch() {
    if (!vibrationEnabled) return;
    final now = DateTime.now();
    if (now.difference(_lastTouch).inMilliseconds < 45) return;
    _lastTouch = now;
    HapticFeedback.selectionClick();
  }

  static Future<void> playKill() async {
    if (vibrationEnabled && (await Vibration.hasVibrator())) {
      Vibration.vibrate(pattern: [0, 85, 35, 145]);
    } else if (vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
    _playSound('kill.wav', volume: 0.34);
  }

  static Future<void> playWin() async {
    if (vibrationEnabled && (await Vibration.hasVibrator())) {
      Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 400]);
    } else if (vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
    _playSound('win.wav', volume: 0.30);
  }
}
