import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/token.dart';
import '../utils/aura_feedback.dart';

class GameProvider with ChangeNotifier {
  static const Duration _postRollSettle = Duration(milliseconds: 150);
  static const Duration _moveAnticipation = Duration(milliseconds: 70);
  static const Duration _stepMoveDuration = Duration(milliseconds: 150);
  static const Duration _entryMoveDuration = Duration(milliseconds: 180);
  static const Duration _postMoveSettle = Duration(milliseconds: 150);
  static const Duration _turnTransitionDelay = Duration(milliseconds: 160);

  List<Player> players = [];
  int currentPlayerIndex = 0;
  int diceValue = 1;
  bool hasRolled = false;
  bool isGameOver = false;
  bool isMoving = false;
  bool isRollingDice = false;
  int diceImpactTick = 0;
  int turnChangeTick = 0;
  int captureImpactTick = 0;
  Offset? captureImpactPosition;
  bool _isDisposed = false;
  final Random _random = Random();

  static const List<Offset> trackCoordinates = [
    Offset(6, 1), Offset(6, 2), Offset(6, 3), Offset(6, 4), Offset(6, 5),
    Offset(5, 6), Offset(4, 6), Offset(3, 6), Offset(2, 6), Offset(1, 6), Offset(0, 6),
    Offset(0, 7), Offset(0, 8),
    Offset(1, 8), Offset(2, 8), Offset(3, 8), Offset(4, 8), Offset(5, 8),
    Offset(6, 9), Offset(6, 10), Offset(6, 11), Offset(6, 12), Offset(6, 13), Offset(6, 14),
    Offset(7, 14), Offset(8, 14),
    Offset(8, 13), Offset(8, 12), Offset(8, 11), Offset(8, 10), Offset(8, 9),
    Offset(9, 8), Offset(10, 8), Offset(11, 8), Offset(12, 8), Offset(13, 8), Offset(14, 8),
    Offset(14, 7), Offset(14, 6),
    Offset(13, 6), Offset(12, 6), Offset(11, 6), Offset(10, 6), Offset(9, 6),
    Offset(8, 5), Offset(8, 4), Offset(8, 3), Offset(8, 2), Offset(8, 1), Offset(8, 0),
    Offset(7, 0), Offset(6, 0),
  ];

  static const Map<PlayerColor, List<Offset>> homeStretch = {
    PlayerColor.red: [Offset(7, 1), Offset(7, 2), Offset(7, 3), Offset(7, 4), Offset(7, 5)],
    PlayerColor.green: [Offset(1, 7), Offset(2, 7), Offset(3, 7), Offset(4, 7), Offset(5, 7)],
    PlayerColor.yellow: [Offset(7, 13), Offset(7, 12), Offset(7, 11), Offset(7, 10), Offset(7, 9)],
    PlayerColor.blue: [Offset(13, 7), Offset(12, 7), Offset(11, 7), Offset(10, 7), Offset(9, 7)],
  };

  static const Map<PlayerColor, List<Offset>> bases = {
    PlayerColor.red: [Offset(2, 2), Offset(2, 3), Offset(3, 2), Offset(3, 3)],
    PlayerColor.green: [Offset(2, 11), Offset(2, 12), Offset(3, 11), Offset(3, 12)],
    PlayerColor.yellow: [Offset(11, 11), Offset(11, 12), Offset(12, 11), Offset(12, 12)],
    PlayerColor.blue: [Offset(11, 2), Offset(11, 3), Offset(12, 2), Offset(12, 3)],
  };

  GameProvider();

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  Offset getBoardPos(int relativePos, PlayerColor color, int tokenId) {
    if (relativePos == -1) return bases[color]![tokenId];
    if (relativePos < 52) {
      int absPos = getAbsolutePosition(color, relativePos);
      return trackCoordinates[absPos];
    }
    if (relativePos < 57) return homeStretch[color]![relativePos - 52];
    return const Offset(7, 7);
  }

  void startGame(int playerCount, bool enableAI) {
    players.clear();
    List<PlayerColor> colors = [PlayerColor.red, PlayerColor.green, PlayerColor.yellow, PlayerColor.blue];
    for (int i = 0; i < playerCount; i++) {
      players.add(Player(
        color: colors[i],
        tokens: List.generate(4, (index) => Token(id: index)),
        isAI: enableAI && i > 0,
      ));
    }
    currentPlayerIndex = 0;
    hasRolled = false;
    isGameOver = false;
    isMoving = false;
    isRollingDice = false;
    diceImpactTick = 0;
    turnChangeTick = 0;
    captureImpactTick = 0;
    captureImpactPosition = null;
    notifyListeners();
  }

  Future<void> rollDice() async {
    if (isGameOver || hasRolled || isMoving || isRollingDice) return;

    isRollingDice = true;
    AuraFeedback.playDiceRoll();
    notifyListeners();

    final result = _random.nextInt(6) + 1;
    const rollDuration = Duration(milliseconds: 600);
    const frameDuration = Duration(milliseconds: 55);
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < rollDuration) {
      diceValue = _random.nextInt(6) + 1;
      notifyListeners();
      await Future.delayed(frameDuration);
      if (isGameOver || _isDisposed) return;
    }

    diceValue = result;
    hasRolled = true;
    isRollingDice = false;
    diceImpactTick++;
    AuraFeedback.playDiceResult(isSix: result == 6);
    notifyListeners();
    await Future.delayed(_postRollSettle);
    if (isGameOver || _isDisposed) return;

    if (!canMoveAnyToken()) {
      Future.delayed(_turnTransitionDelay, () {
        if (!isGameOver) nextTurn();
      });
    } else if (players[currentPlayerIndex].isAI) {
      Future.delayed(_turnTransitionDelay, () {
        if (!isGameOver) playAITurn();
      });
    }
  }

  bool canMoveAnyToken() {
    for (var token in players[currentPlayerIndex].tokens) {
      if (canMoveToken(token)) return true;
    }
    return false;
  }

  bool canMoveToken(Token token) {
    if (!hasRolled || isRollingDice) return false;
    if (token.isFinished) return false;
    if (token.position == -1) return diceValue == 6;
    if (token.position + diceValue > 57) return false;
    return true;
  }

  bool isTokenMovable(Token token) {
    return hasRolled && !isMoving && !isRollingDice && canMoveToken(token);
  }

  Offset? getMoveTarget(Token token, PlayerColor color) {
    if (!isTokenMovable(token)) return null;
    final targetPosition = token.position == -1 ? 0 : token.position + diceValue;
    return getBoardPos(targetPosition, color, token.id);
  }

  Future<void> moveToken(Token token) async {
    if (isGameOver || !hasRolled || isMoving || isRollingDice || !canMoveToken(token)) return;

    isMoving = true;
    bool extraTurn = false;
    notifyListeners();
    await Future.delayed(_moveAnticipation);
    if (isGameOver || _isDisposed) {
      isMoving = false;
      return;
    }

    if (token.position == -1) {
      token.position = 0;
      AuraFeedback.playMove();
      notifyListeners();
      await Future.delayed(_entryMoveDuration);
    } else {
      for (int step = 0; step < diceValue; step++) {
        if (isGameOver || _isDisposed) return;
        token.position += 1;
        AuraFeedback.playMove();
        notifyListeners();
        await Future.delayed(_stepMoveDuration);
      }
    }

    await Future.delayed(_postMoveSettle);

    if (isGameOver) {
      isMoving = false;
      return;
    }

    if (token.position == 57) {
      token.isFinished = true;
      extraTurn = true;
      AuraFeedback.playWin();
    } else if (token.position < 52) {
      if (await checkKill(token)) {
        extraTurn = true;
        AuraFeedback.playKill();
      }
    }

    if (players[currentPlayerIndex].hasWon) {
      isGameOver = true;
      AuraFeedback.playWin();
      isMoving = false;
      notifyListeners();
      return;
    }

    isMoving = false;
    if (diceValue == 6 || extraTurn) {
      hasRolled = false;
      turnChangeTick++;
      notifyListeners();
      if (players[currentPlayerIndex].isAI && !isGameOver) {
        Future.delayed(_turnTransitionDelay, () {
          if (!isGameOver) rollDice();
        });
      }
    } else {
      Future.delayed(_turnTransitionDelay, () {
        if (!isGameOver) nextTurn();
      });
    }
  }

  Future<bool> checkKill(Token token) async {
    int absolutePos = getAbsolutePosition(players[currentPlayerIndex].color, token.position);
    if (isSafeZone(absolutePos)) return false;

    bool killed = false;
    final capturedTokens = <Token>[];
    for (int i = 0; i < players.length; i++) {
      if (i == currentPlayerIndex) continue;
      for (var opponentToken in players[i].tokens) {
        if (opponentToken.position >= 0 && opponentToken.position < 52) {
          int oppAbsolutePos = getAbsolutePosition(players[i].color, opponentToken.position);
          if (oppAbsolutePos == absolutePos) {
            opponentToken.isCaptured = true;
            capturedTokens.add(opponentToken);
            killed = true;
          }
        }
      }
    }
    if (capturedTokens.isNotEmpty) {
      captureImpactPosition = getBoardPos(token.position, players[currentPlayerIndex].color, token.id);
      captureImpactTick++;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 320));
      for (final capturedToken in capturedTokens) {
        capturedToken.position = -1;
        capturedToken.isCaptured = false;
      }
      captureImpactPosition = null;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 120));
    }
    return killed;
  }

  int getAbsolutePosition(PlayerColor color, int relativePos) {
    if (relativePos >= 52) return -1;
    int offset = 0;
    switch (color) {
      case PlayerColor.red: offset = 0; break;
      case PlayerColor.green: offset = 13; break;
      case PlayerColor.yellow: offset = 26; break;
      case PlayerColor.blue: offset = 39; break;
    }
    return (relativePos + offset) % 52;
  }

  bool isSafeZone(int absolutePos) {
    const safeZones = [0, 8, 13, 21, 26, 34, 39, 47];
    return safeZones.contains(absolutePos);
  }

  void nextTurn() {
    if (isGameOver || isRollingDice || isMoving) return;
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    hasRolled = false;
    turnChangeTick++;
    notifyListeners();

    if (players[currentPlayerIndex].isAI && !isGameOver) {
      Future.delayed(_turnTransitionDelay, () {
        if (!isGameOver) rollDice();
      });
    }
  }

  void playAITurn() async {
    if (isGameOver || isMoving) return;
    
    List<Token> movableTokens = players[currentPlayerIndex].tokens.where((t) => canMoveToken(t)).toList();
    if (movableTokens.isEmpty) {
      nextTurn();
      return;
    }

    Token? selectedToken;
    // Prefer entering
    var enteringToken = movableTokens.where((t) => t.position == -1).toList();
    if (enteringToken.isNotEmpty) {
      selectedToken = enteringToken.first;
    } else {
      // Prefer killing
      for (var t in movableTokens) {
        if (t.position >= 0 && t.position + diceValue < 52) {
          int targetAbsolutePos = getAbsolutePosition(players[currentPlayerIndex].color, t.position + diceValue);
          if (!isSafeZone(targetAbsolutePos)) {
            for (int i = 0; i < players.length; i++) {
              if (i == currentPlayerIndex) continue;
              if (players[i].tokens.any((op) => op.position >= 0 && op.position < 52 && getAbsolutePosition(players[i].color, op.position) == targetAbsolutePos)) {
                selectedToken = t;
                break;
              }
            }
          }
        }
        if (selectedToken != null) break;
      }
      
      if (selectedToken == null) {
        // Prefer finishing
        var finishingToken = movableTokens.where((t) => t.position + diceValue == 57).toList();
        if (finishingToken.isNotEmpty) {
          selectedToken = finishingToken.first;
        } else {
          // Otherwise, move most advanced token
          movableTokens.sort((a, b) => b.position.compareTo(a.position));
          selectedToken = movableTokens.first;
        }
      }
    }

    await moveToken(selectedToken);
  }
}
