import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/board_widget.dart';
import '../widgets/dice_widget.dart';
import 'home_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  bool _dialogShowing = false;
  late AnimationController _shakeController;
  int _lastDiceImpactTick = 0;
  int _lastCaptureImpactTick = 0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    if (game.diceImpactTick != _lastDiceImpactTick) {
      _lastDiceImpactTick = game.diceImpactTick;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _shakeController.forward(from: 0);
      });
    }
    if (game.captureImpactTick != _lastCaptureImpactTick) {
      _lastCaptureImpactTick = game.captureImpactTick;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _shakeController.forward(from: 0);
      });
    }
    
    if (game.isGameOver && !_dialogShowing) {
      _dialogShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text('Game Over', style: TextStyle(color: Color(0xFF00FFCC))),
            content: Text('${game.players[game.currentPlayerIndex].color.name.toUpperCase()} Wins!', style: const TextStyle(color: Colors.white, fontSize: 24)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                },
                child: const Text('HOME', style: TextStyle(color: Color(0xFFFF0055))),
              )
            ],
          ),
        );
      });
    }

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shake = Curves.easeOut.transform(_shakeController.value);
        final dx = (1 - shake) * 1.6 * (shake < 0.5 ? 1 : -1);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Stack(
        children: [
          Scaffold(
        appBar: AppBar(
          title: const Text('Aura Quantum Ludo'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
              },
            )
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              children: [
                _TurnHeader(game: game),
                const SizedBox(height: 14),
                const Expanded(
                  child: Center(child: BoardWidget()),
                ),
                const SizedBox(height: 14),
                const DiceWidget(),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: _GrainOverlay()),
          ),
        ],
      ),
    );
  }
}

class _GrainOverlay extends StatelessWidget {
  const _GrainOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GrainPainter(),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.018);
    const step = 7.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = (y ~/ step).isEven ? 0 : step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 0.45, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TurnHeader extends StatefulWidget {
  const _TurnHeader({required this.game});

  final GameProvider game;

  @override
  State<_TurnHeader> createState() => _TurnHeaderState();
}

class _TurnHeaderState extends State<_TurnHeader> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _turnEntryController;
  int _lastTurnChangeTick = -1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _turnEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _turnEntryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final player = game.players[game.currentPlayerIndex];
    if (game.turnChangeTick != _lastTurnChangeTick) {
      _lastTurnChangeTick = game.turnChangeTick;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _turnEntryController.forward(from: 0);
      });
    }
    final status = game.isRollingDice
        ? 'Rolling'
        : game.isMoving
            ? 'Moving'
            : game.hasRolled
                ? 'Choose token'
                : player.isAI
                    ? 'AI turn'
                    : 'Your roll';

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _turnEntryController]),
      builder: (context, child) {
        final pulse = Curves.easeInOut.transform(_pulseController.value);
        final turnReveal = Curves.easeOutCubic.transform(_turnEntryController.value);
        final yourTurnBoost = (!player.isAI && !game.hasRolled && !game.isRollingDice && !game.isMoving)
            ? (1 - turnReveal) * 0.20
            : 0.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          transform: Matrix4.identity()
            ..translateByDouble(0.0, (1 - turnReveal) * 10, 0.0, 1.0)
            ..scaleByDouble(1.0 + yourTurnBoost * 0.18, 1.0 + yourTurnBoost * 0.12, 1.0, 1.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1A1D22),
                const Color(0xFF121418),
                player.uiColor.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: player.uiColor.withValues(alpha: 0.58 + pulse * 0.25 + yourTurnBoost * 0.18),
              width: 1.2 + pulse * 0.6 + yourTurnBoost * 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
              BoxShadow(
                color: player.uiColor.withValues(alpha: 0.14 + pulse * 0.14 + yourTurnBoost * 0.18),
                blurRadius: 18 + pulse * 12 + yourTurnBoost * 12,
                spreadRadius: 1 + pulse + yourTurnBoost * 1.8,
              ),
            ],
          ),
          child: Opacity(
            opacity: 0.84 + (turnReveal * 0.16),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          AnimatedScale(
            scale: 1.0 + (_pulseController.value * 0.12) + ((1 - _turnEntryController.value) * 0.10),
            duration: const Duration(milliseconds: 180),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: player.uiColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: player.uiColor.withValues(alpha: 0.75),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.22),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                );
              },
              child: Text(
                '${player.color.name.toUpperCase()} TURN',
                key: ValueKey(player.color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: player.uiColor,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              status,
              key: ValueKey(status),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
