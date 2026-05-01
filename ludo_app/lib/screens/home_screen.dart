import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _playerCount = 2;
  bool _enableAI = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF1A1A1A), Color(0xFF080808)],
          ),
        ),
        child: Stack(
          children: [
            // Animated Background Particles
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BackgroundPainter(_animationController.value),
                  child: Container(),
                );
              },
            ),
            
            // Background Decorative Elements
            Positioned(
              top: -100,
              right: -100,
              child: _buildBlurCircle(const Color(0xFF00FFCC).withValues(alpha: 0.1), 300),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: _buildBlurCircle(const Color(0xFFFF0055).withValues(alpha: 0.1), 300),
            ),
            
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 60),
                      _buildControlPanel(),
                      const SizedBox(height: 60),
                      _buildStartButton(),
                      const SizedBox(height: 20),
                      _buildSettingsButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'LUDO',
          style: GoogleFonts.orbitron(
            fontSize: 72,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF00FFCC),
            letterSpacing: 10,
            shadows: [
              const Shadow(color: Color(0xFF00FFCC), blurRadius: 25),
              const Shadow(color: Colors.white24, offset: Offset(2, 2)),
            ],
          ),
        ),
        Text(
          'AURA QUANTUM',
          style: GoogleFonts.rajdhani(
            fontSize: 20,
            letterSpacing: 12,
            fontWeight: FontWeight.w300,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildOptionRow(
            'PLAYERS',
            DropdownButton<int>(
              value: _playerCount,
              dropdownColor: const Color(0xFF1A1A1A),
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00FFCC)),
              items: [2, 3, 4].map((e) => DropdownMenuItem(
                value: e, 
                child: Text('$e', style: const TextStyle(color: Color(0xFF00FFCC), fontWeight: FontWeight.bold))
              )).toList(),
              onChanged: (v) => setState(() => _playerCount = v!),
            ),
          ),
          const Divider(color: Colors.white10, height: 30),
          _buildOptionRow(
            'AI ASSIST',
            Switch(
              value: _enableAI,
              activeColor: const Color(0xFF00FFCC),
              inactiveThumbColor: Colors.white24,
              onChanged: (v) => setState(() => _enableAI = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(String label, Widget control) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.rajdhani(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 2)),
        control,
      ],
    );
  }

  Widget _buildStartButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0055).withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: const Color(0xFFFF0055).withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF0055), Color(0xFFFF4081)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            elevation: 0,
          ),
          onPressed: () {
            context.read<GameProvider>().startGame(_playerCount, _enableAI);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
          },
          child: Text(
            'INITIALIZE GAME',
            style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return TextButton.icon(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
      icon: const Icon(Icons.settings_outlined, color: Colors.white38, size: 18),
      label: const Text('SETTINGS', style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 2)),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double progress;
  _BackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF00FFCC).withValues(alpha: 0.05);
    final random = math.Random(42);
    
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height + progress * size.height) % size.height;
      final radius = random.nextDouble() * 3 + 1;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
