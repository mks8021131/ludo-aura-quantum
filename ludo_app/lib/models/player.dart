import 'package:flutter/material.dart';
import 'token.dart';

enum PlayerColor { red, green, yellow, blue }

class Player {
  final PlayerColor color;
  final List<Token> tokens;
  final bool isAI;
  
  Player({required this.color, required this.tokens, this.isAI = false});
  
  Color get uiColor {
    switch (color) {
      case PlayerColor.red: return Colors.redAccent;
      case PlayerColor.green: return Colors.greenAccent;
      case PlayerColor.yellow: return Colors.yellowAccent;
      case PlayerColor.blue: return Colors.lightBlueAccent;
    }
  }

  bool get hasWon => tokens.every((t) => t.isFinished);
}
