import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/player.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    double screenWidth = MediaQuery.of(context).size.width;
    double boardSize = screenWidth * 0.95;
    double cellSize = boardSize / 15;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1D22),
            Color(0xFF111418),
            Color(0xFF171B20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF303030), width: 1.5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.48),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: game.players.isEmpty
                ? Colors.transparent
                : game.players[game.currentPlayerIndex].uiColor.withValues(alpha: 0.10),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.55),
                    radius: 0.95,
                    colors: [
                      Colors.white.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.72,
                    colors: [
                      game.players.isEmpty
                          ? const Color(0xFF00FFCC).withValues(alpha: 0.04)
                          : game.players[game.currentPlayerIndex].uiColor.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.95,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.28),
                    ],
                    stops: const [0.62, 1.0],
                  ),
                ),
              ),
            ),
          ),
          ..._buildBases(cellSize, game),
          ..._buildTrack(cellSize),
          ..._buildHomeStretch(cellSize),
          _EnergyCenter(cellSize: cellSize),
          if (game.captureImpactPosition != null)
            _CaptureFlash(
              key: ValueKey(game.captureImpactTick),
              color: game.players[game.currentPlayerIndex].uiColor,
              position: game.captureImpactPosition!,
              cellSize: cellSize,
            ),
          ..._buildMoveTargets(game, cellSize),
          ..._buildTokens(game, cellSize),
        ],
      ),
    );
  }

  List<Widget> _buildBases(double cellSize, GameProvider game) {
    List<Widget> baseWidgets = [];
    GameProvider.bases.forEach((color, positions) {
      Color uiColor;
      switch (color) {
        case PlayerColor.red: uiColor = Colors.redAccent; break;
        case PlayerColor.green: uiColor = Colors.greenAccent; break;
        case PlayerColor.yellow: uiColor = Colors.yellowAccent; break;
        case PlayerColor.blue: uiColor = Colors.lightBlueAccent; break;
      }
      
      bool isCurrent = game.players.isNotEmpty && game.players[game.currentPlayerIndex].color == color;

      Offset basePos = positions[0];
      baseWidgets.add(Positioned(
        left: (basePos.dy - 0.5) * cellSize,
        top: (basePos.dx - 0.5) * cellSize,
        width: cellSize * 3,
        height: cellSize * 3,
        child: _PulseShell(
          color: uiColor,
          enabled: isCurrent,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: uiColor.withValues(alpha: isCurrent ? 0.10 : 0.045),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: uiColor.withValues(alpha: isCurrent ? 0.90 : 0.28),
                width: isCurrent ? 2.5 : 1.5,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: uiColor.withValues(alpha: 0.22),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ));

      for (var pos in positions) {
        baseWidgets.add(Positioned(
          left: pos.dy * cellSize,
          top: pos.dx * cellSize,
          width: cellSize,
          height: cellSize,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: uiColor.withValues(alpha: isCurrent ? 0.16 : 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: uiColor.withValues(alpha: isCurrent ? 0.7 : 0.38), width: 1.4),
            ),
          ),
        ));
      }
    });
    return baseWidgets;
  }

  List<Widget> _buildTrack(double cellSize) {
    List<Widget> cells = [];
    for (int i = 0; i < GameProvider.trackCoordinates.length; i++) {
      var pos = GameProvider.trackCoordinates[i];
      bool isSafe = [0, 8, 13, 21, 26, 34, 39, 47].contains(i);
      cells.add(Positioned(
        left: pos.dy * cellSize,
        top: pos.dx * cellSize,
        width: cellSize,
        height: cellSize,
        child: Container(
          decoration: BoxDecoration(
            color: isSafe ? null : Colors.black.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
            gradient: isSafe
                ? LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.075),
                      Colors.white.withValues(alpha: 0.025),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: isSafe ? Icon(Icons.shield_outlined, color: Colors.white.withValues(alpha: 0.24), size: 14) : null,
        ),
      ));
    }
    return cells;
  }

  List<Widget> _buildHomeStretch(double cellSize) {
    List<Widget> cells = [];
    GameProvider.homeStretch.forEach((color, positions) {
      Color uiColor;
      switch (color) {
        case PlayerColor.red: uiColor = Colors.redAccent; break;
        case PlayerColor.green: uiColor = Colors.greenAccent; break;
        case PlayerColor.yellow: uiColor = Colors.yellowAccent; break;
        case PlayerColor.blue: uiColor = Colors.lightBlueAccent; break;
      }
      for (int i = 0; i < positions.length; i++) {
        var pos = positions[i];
        cells.add(Positioned(
          left: pos.dy * cellSize,
          top: pos.dx * cellSize,
          width: cellSize,
          height: cellSize,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  uiColor.withValues(alpha: 0.16),
                  uiColor.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: uiColor.withValues(alpha: 0.2), width: 1),
            ),
          ),
        ));
      }
    });
    return cells;
  }

  List<Widget> _buildMoveTargets(GameProvider game, double cellSize) {
    if (game.players.isEmpty || !game.hasRolled || game.isMoving || game.isRollingDice) {
      return [];
    }

    final player = game.players[game.currentPlayerIndex];
    return player.tokens.map((token) {
      final target = game.getMoveTarget(token, player.color);
      if (target == null) return const SizedBox.shrink();

      return Positioned(
        left: target.dy * cellSize + (cellSize * 0.10),
        top: target.dx * cellSize + (cellSize * 0.10),
        width: cellSize * 0.80,
        height: cellSize * 0.80,
        child: IgnorePointer(
          child: _MoveTargetHint(color: player.uiColor),
        ),
      );
    }).toList();
  }

  List<Widget> _buildTokens(GameProvider game, double cellSize) {
    List<Widget> widgets = [];
    Map<Offset, int> counts = {};

    for (var player in game.players) {
      for (var token in player.tokens) {
        Offset position = game.getBoardPos(token.position, player.color, token.id);
        final isCurrentPlayer = game.players.isNotEmpty && game.currentPlayerIndex == game.players.indexOf(player);
        final isMovable = isCurrentPlayer && !player.isAI && game.isTokenMovable(token);

        counts[position] = (counts[position] ?? 0) + 1;
        int overlapIndex = counts[position]! - 1;
        double offsetAmount = overlapIndex * (cellSize * 0.15);

        widgets.add(
          AnimatedPositioned(
            duration: const Duration(milliseconds: 230),
            curve: Curves.easeOutCubic,
            left: position.dy * cellSize + (cellSize * 0.05) + offsetAmount,
            top: position.dx * cellSize + (cellSize * 0.05) + offsetAmount,
            width: cellSize * 0.9,
            height: cellSize * 0.9,
            key: ValueKey('token_${player.color}_${token.id}'),
            child: Center(
              child: SizedBox(
                width: cellSize * 0.7,
                height: cellSize * 0.7,
                child: _TokenPiece(
                  color: player.uiColor,
                  isFinished: token.isFinished,
                  isCaptured: token.isCaptured,
                  isMovable: isMovable,
                  isActivePlayer: isCurrentPlayer,
                  position: token.position,
                  onTap: () {
                    if (isMovable) game.moveToken(token);
                  },
                ),
              ),
            ),
          )
        );
      }
    }
    return widgets;
  }
}

class _EnergyCenter extends StatefulWidget {
  const _EnergyCenter({required this.cellSize});

  final double cellSize;

  @override
  State<_EnergyCenter> createState() => _EnergyCenterState();
}

class _EnergyCenterState extends State<_EnergyCenter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 6 * widget.cellSize,
      top: 6 * widget.cellSize,
      width: 3 * widget.cellSize,
      height: 3 * widget.cellSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = 0.5 + math.sin(_controller.value * math.pi * 2) * 0.5;
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.28),
                  const Color(0xFF00FFCC).withValues(alpha: 0.32),
                  const Color(0xFFFFD166).withValues(alpha: 0.18),
                  const Color(0xFFFF4D7D).withValues(alpha: 0.12),
                  const Color(0xFF111111),
                ],
                stops: const [0.0, 0.26, 0.52, 0.76, 1.0],
              ),
              border: Border.all(color: const Color(0xFF00FFCC).withValues(alpha: 0.38), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FFCC).withValues(alpha: 0.18 + pulse * 0.08),
                  blurRadius: 18 + pulse * 8,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Transform.rotate(
              angle: _controller.value * math.pi * 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: const Center(child: Icon(Icons.api_rounded, color: Colors.white60, size: 40)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TokenPiece extends StatefulWidget {
  const _TokenPiece({
    required this.color,
    required this.isFinished,
    required this.isCaptured,
    required this.isMovable,
    required this.isActivePlayer,
    required this.position,
    required this.onTap,
  });

  final Color color;
  final bool isFinished;
  final bool isCaptured;
  final bool isMovable;
  final bool isActivePlayer;
  final int position;
  final VoidCallback onTap;

  @override
  State<_TokenPiece> createState() => _TokenPieceState();
}

class _TokenPieceState extends State<_TokenPiece> with SingleTickerProviderStateMixin {
  late AnimationController _captureController;
  Timer? _motionTimer;
  bool _pressed = false;
  bool _bounce = false;
  bool _isInMotion = false;

  @override
  void initState() {
    super.initState();
    _captureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    if (widget.isCaptured) _captureController.forward();
  }

  @override
  void dispose() {
    _motionTimer?.cancel();
    _captureController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TokenPiece oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      _motionTimer?.cancel();
      _isInMotion = true;
      _bounce = true;
      _motionTimer = Timer(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        setState(() {
          _isInMotion = false;
          _bounce = false;
        });
      });
    }
    if (!oldWidget.isCaptured && widget.isCaptured) {
      _captureController.forward(from: 0);
    } else if (oldWidget.isCaptured && !widget.isCaptured) {
      _captureController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleX = _pressed ? 0.97 : (_isInMotion ? 1.05 : (_bounce ? 1.14 : (widget.isMovable ? 1.05 : 1.0)));
    final scaleY = _pressed ? 0.97 : (_isInMotion ? 0.96 : (_bounce ? 1.10 : (widget.isMovable ? 1.05 : 1.0)));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.isMovable
          ? (_) {
              setState(() => _pressed = true);
              widget.onTap();
            }
          : null,
      onTapCancel: widget.isMovable ? () => setState(() => _pressed = false) : null,
      onTapUp: widget.isMovable ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedBuilder(
        animation: _captureController,
        builder: (context, child) {
          final captureValue = Curves.easeOutCubic.transform(_captureController.value);
          final shake = widget.isCaptured ? (1 - captureValue) * 5 : 0.0;
          final dx = shake == 0 ? 0.0 : (shake * (DateTime.now().millisecond.isEven ? 1 : -1));
          final captureScale = widget.isCaptured ? (1.0 - captureValue * 0.38) : 1.0;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(
              scale: captureScale,
              child: Opacity(
                opacity: widget.isCaptured ? (1 - captureValue).clamp(0.12, 1.0).toDouble() : 1.0,
                child: child,
              ),
            ),
          );
        },
        child: AnimatedScale(
          scale: 1.0,
          duration: Duration(milliseconds: _pressed ? 70 : 150),
          curve: Curves.easeOutBack,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: _isInMotion ? 0.55 : 0,
              sigmaY: _isInMotion ? 0.18 : 0,
            ),
            child: AnimatedContainer(
                duration: Duration(milliseconds: _pressed ? 70 : 170),
                curve: Curves.easeOutBack,
                transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
                transformAlignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.38),
                      widget.color,
                      widget.color.withValues(alpha: 0.80),
                    ],
                    stops: const [0.0, 0.58, 1.0],
                    center: const Alignment(-0.35, -0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.50),
                      blurRadius: 7,
                      offset: const Offset(0, 4),
                    ),
                    if (_isInMotion)
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(-5, 0),
                      ),
                    if (widget.isActivePlayer)
                      BoxShadow(
                        color: widget.color.withValues(alpha: widget.isMovable ? 0.56 : 0.28),
                        blurRadius: widget.isMovable ? 18 : 11,
                        spreadRadius: widget.isMovable ? 1.4 : 0,
                      ),
                    if (widget.isCaptured)
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                  ],
                  border: Border.all(
                    color: widget.isMovable ? Colors.white : Colors.white.withValues(alpha: 0.82),
                    width: widget.isMovable ? 2.4 : 1.8,
                  ),
                ),
                child: Center(
                  child: widget.isFinished
                      ? const Icon(Icons.star, size: 14, color: Colors.white)
                      : widget.isMovable
                          ? Icon(Icons.touch_app_rounded, size: 13, color: Colors.white.withValues(alpha: 0.9))
                          : null,
                ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureFlash extends StatefulWidget {
  const _CaptureFlash({
    super.key,
    required this.color,
    required this.position,
    required this.cellSize,
  });

  final Color color;
  final Offset position;
  final double cellSize;

  @override
  State<_CaptureFlash> createState() => _CaptureFlashState();
}

class _CaptureFlashState extends State<_CaptureFlash> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dy * widget.cellSize - widget.cellSize * 0.05,
      top: widget.position.dx * widget.cellSize - widget.cellSize * 0.05,
      width: widget.cellSize * 1.1,
      height: widget.cellSize * 1.1,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = Curves.easeOutCubic.transform(_controller.value);
            return Transform.scale(
              scale: 0.72 + value * 0.72,
              child: Opacity(
                opacity: (1 - value).clamp(0.0, 1.0).toDouble(),
                child: child,
              ),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.34),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.42),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveTargetHint extends StatefulWidget {
  const _MoveTargetHint({required this.color});

  final Color color;

  @override
  State<_MoveTargetHint> createState() => _MoveTargetHintState();
}

class _MoveTargetHintState extends State<_MoveTargetHint> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = Curves.easeInOut.transform(_controller.value);
        return Transform.scale(
          scale: 0.88 + (pulse * 0.14),
          child: Opacity(opacity: 0.58 + (pulse * 0.32), child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.12),
          border: Border.all(color: widget.color.withValues(alpha: 0.75), width: 2),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.30),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseShell extends StatefulWidget {
  const _PulseShell({
    required this.color,
    required this.enabled,
    required this.borderRadius,
    required this.child,
  });

  final Color color;
  final bool enabled;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  State<_PulseShell> createState() => _PulseShellState();
}

class _PulseShellState extends State<_PulseShell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulseShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final pulse = widget.enabled ? Curves.easeInOut.transform(_controller.value) : 0.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.10 + pulse * 0.18),
                blurRadius: 14 + pulse * 12,
                spreadRadius: pulse * 2,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}
