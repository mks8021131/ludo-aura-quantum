import 'package:flutter/material.dart';
import '../utils/aura_feedback.dart';

enum TurnSpeed { slow, normal, fast }
enum BoardStyle { flat, glass, gradient }

class SettingsProvider with ChangeNotifier {
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  bool diceSoundEnabled = true;
  bool backgroundMusicEnabled = true;
  bool autoPlay = false;
  double musicVolume = 0.5;
  
  int playerCount = 4;
  TurnSpeed turnSpeed = TurnSpeed.normal;
  BoardStyle boardStyle = BoardStyle.gradient;

  SettingsProvider() {
    _loadSettings();
  }

  void _loadSettings() {
    AuraFeedback.init(vibrationEnabled, soundEnabled, diceSnd: diceSoundEnabled);
  }

  void setPlayerCount(int count) {
    playerCount = count;
    notifyListeners();
  }

  void setTurnSpeed(TurnSpeed speed) {
    turnSpeed = speed;
    notifyListeners();
  }

  void setBoardStyle(BoardStyle style) {
    boardStyle = style;
    notifyListeners();
  }

  void toggleAutoPlay() {
    autoPlay = !autoPlay;
    notifyListeners();
  }

  void toggleSound() {
    AuraFeedback.playUIClick();
    soundEnabled = !soundEnabled;
    AuraFeedback.init(vibrationEnabled, soundEnabled, diceSnd: diceSoundEnabled);
    notifyListeners();
  }

  void toggleVibration() {
    AuraFeedback.playUIClick();
    vibrationEnabled = !vibrationEnabled;
    AuraFeedback.init(vibrationEnabled, soundEnabled, diceSnd: diceSoundEnabled);
    notifyListeners();
  }

  void toggleDiceSound() {
    AuraFeedback.playUIClick();
    diceSoundEnabled = !diceSoundEnabled;
    AuraFeedback.init(vibrationEnabled, soundEnabled, diceSnd: diceSoundEnabled);
    notifyListeners();
  }

  void toggleBackgroundMusic() {
    AuraFeedback.playUIClick();
    backgroundMusicEnabled = !backgroundMusicEnabled;
    notifyListeners();
  }

  void setMusicVolume(double volume) {
    musicVolume = volume;
    notifyListeners();
  }

  void resetSettings() {
    soundEnabled = true;
    vibrationEnabled = true;
    diceSoundEnabled = true;
    backgroundMusicEnabled = true;
    autoPlay = false;
    musicVolume = 0.5;
    playerCount = 4;
    turnSpeed = TurnSpeed.normal;
    boardStyle = BoardStyle.gradient;
    AuraFeedback.init(vibrationEnabled, soundEnabled, diceSnd: diceSoundEnabled);
    notifyListeners();
  }
}
