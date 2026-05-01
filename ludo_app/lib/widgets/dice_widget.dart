import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import 'dart:math' as math;

class DiceWidget extends StatefulWidget {
  const DiceWidget({super.key});

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _impactController;
  late Animation<double> _rollCurve;
  bool _wasRolling = false;
  bool _pressed = false;
  
  // Random rotation vectors for the roll animation
  double _rx = 0;
  double _ry = 0;
  double _rz = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _impactController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rollCurve = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    _impactController.dispose();
    super.dispose();
  }

  void _generateRandomRotation() {
    final rand = math.Random();
    _rx = rand.nextDouble() * math.pi * 8;
    _ry = rand.nextDouble() * math.pi * 8;
    _rz = rand.nextDouble() * math.pi * 8;
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final settings = context.watch<SettingsProvider>();
    
    if (game.players.isEmpty) return const SizedBox.shrink();
    
    final canRoll = !game.players[game.currentPlayerIndex].isAI &&
        !game.hasRolled &&
        !game.isMoving &&
        !game.isRollingDice;

    if (game.isRollingDice && !_wasRolling) {
      _generateRandomRotation();
      _impactController.reset();
      _controller.forward(from: 0);
    } else if (!game.isRollingDice && _wasRolling) {
      _controller.stop();
      _controller.animateTo(1, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
      _impactController.forward(from: 0);
    }
    _wasRolling = game.isRollingDice;
    
    return GestureDetector(
      onTapDown: canRoll ? (_) {
        setState(() => _pressed = true);
        game.rollDice();
      } : null,
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, _impactController]),
        builder: (context, child) {
          final rollVal = _rollCurve.value;
          final impactVal = Curves.elasticOut.transform(_impactController.value);
          final rolling = game.isRollingDice;
          final accentColor = game.players[game.currentPlayerIndex].uiColor;
          
          final scale = _pressed ? 0.92 : (rolling ? 1.15 : 1.0 + (impactVal * 0.05));
          final shake = rolling ? 0.0 : math.sin(impactVal * math.pi * 4) * (1 - _impactController.value) * 5.0;
          
          return Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Shadow
                Transform.translate(
                  offset: Offset(0, 40 + (rolling ? 10 : 0)),
                  child: Transform.scale(
                    scaleX: 1.2 + (rolling ? 0.2 : 0),
                    scaleY: 0.3,
                    child: Container(
                      width: 60,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: rolling ? 0.2 : 0.4),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 3D Cube Container
                Transform.translate(
                  offset: Offset(shake, -impactVal * 10),
                  child: Transform.scale(
                    scale: scale,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002) // Perspective
                        ..rotateX(rolling ? rollVal * _rx : 0)
                        ..rotateY(rolling ? rollVal * _ry : 0)
                        ..rotateZ(rolling ? rollVal * _rz : 0),
                      child: _Cube(
                        value: game.diceValue,
                        color: accentColor,
                        isRolling: rolling,
                      ),
                    ),
                  ),
                ),
                
                // Glow effect when not rolling
                if (!rolling && game.hasRolled)
                  IgnorePointer(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3 * (1 - _impactController.value)),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Cube extends StatelessWidget {
  final int value;
  final Color color;
  final bool isRolling;

  const _Cube({required this.value, required this.color, required this.isRolling});

  @override
  Widget build(BuildContext context) {
    const double size = 70.0;
    return Stack(
      children: [
        // We only really see the front face clearly when it stops
        // In a real 3D engine we'd have 6 faces. Here we'll simulate the main face.
        _CubeFace(
          size: size,
          value: value,
          color: color,
          opacity: 1.0,
          transform: Matrix4.identity(),
        ),
        // Simplified side faces for 3D depth
        _CubeFace(
          size: size,
          value: (value % 6) + 1,
          color: color.withValues(alpha: 0.8),
          opacity: 0.4,
          transform: Matrix4.identity()..translate(0.0, 0.0, -size)..rotateY(math.pi / 2),
        ),
      ],
    );
  }
}

class _CubeFace extends StatelessWidget {
  final double size;
  final int value;
  final Color color;
  final double opacity;
  final Matrix4 transform;

  const _CubeFace({
    required this.size,
    required this.value,
    required this.color,
    required this.opacity,
    required this.transform,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFFF0F0F0),
                color.withValues(alpha: 0.1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Center(
            child: _DiceDots(value: value, color: color),
          ),
        ),
      ),
    );
  }
}

class _DiceDots extends StatelessWidget {
  final int value;
  final Color color;

  const _DiceDots({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final List<int> dotIndices = _getDotIndices(value);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final bool hasDot = dotIndices.contains(index);
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasDot ? const Color(0xFF2D2D2D) : Colors.transparent,
              boxShadow: hasDot ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 2,
                  spreadRadius: 1,
                )
              ] : null,
            ),
          );
        },
      ),
    );
  }

  List<int> _getDotIndices(int value) {
    switch (value) {
      case 1: return [4];
      case 2: return [0, 8];
      case 3: return [0, 4, 8];
      case 4: return [0, 2, 6, 8];
      case 5: return [0, 2, 4, 6, 8];
      case 6: return [0, 2, 3, 5, 6, 8];
      default: return [];
    }
  }
}
