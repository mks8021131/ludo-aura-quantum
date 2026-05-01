import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'SETTINGS',
          style: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            color: colorScheme.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface.withValues(alpha: 0.7), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 100,
              left: -50,
              child: _buildBlurCircle(colorScheme.primary.withValues(alpha: 0.1), 250),
            ),
            Positioned(
              bottom: 100,
              right: -50,
              child: _buildBlurCircle(colorScheme.secondary.withValues(alpha: 0.1), 250),
            ),
            
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSectionHeader(context, 'GAMEPLAY'),
                  const SizedBox(height: 12),
                  _buildPlayerCountSelector(context, settings),
                  const SizedBox(height: 12),
                  _buildDropdownSetting<TurnSpeed>(
                    context,
                    'Turn Speed',
                    Icons.speed_rounded,
                    settings.turnSpeed,
                    TurnSpeed.values,
                    (v) => settings.setTurnSpeed(v!),
                  ),
                  const SizedBox(height: 12),
                  _buildToggleSetting(
                    context,
                    'Auto-Play (Test Mode)',
                    Icons.smart_toy_rounded,
                    settings.autoPlay,
                    (v) => settings.toggleAutoPlay(),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'APPEARANCE'),
                  const SizedBox(height: 12),
                  _buildThemeSelector(context, themeProvider),
                  const SizedBox(height: 12),
                  _buildDropdownSetting<BoardStyle>(
                    context,
                    'Board Style',
                    Icons.dashboard_customize_rounded,
                    settings.boardStyle,
                    BoardStyle.values,
                    (v) => settings.setBoardStyle(v!),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'EFFECTS'),
                  const SizedBox(height: 12),
                  _buildToggleSetting(
                    context,
                    'Sound FX',
                    Icons.volume_up_rounded,
                    settings.soundEnabled,
                    (v) => settings.toggleSound(),
                  ),
                  const SizedBox(height: 12),
                  _buildToggleSetting(
                    context,
                    'Dice Sound',
                    Icons.casino_rounded,
                    settings.diceSoundEnabled,
                    (v) => settings.toggleDiceSound(),
                  ),
                  const SizedBox(height: 12),
                  _buildToggleSetting(
                    context,
                    'Vibration',
                    Icons.vibration_rounded,
                    settings.vibrationEnabled,
                    (v) => settings.toggleVibration(),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'MISC'),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    context,
                    'Reset Game',
                    Icons.refresh_rounded,
                    Colors.orangeAccent,
                    () {
                      // Logic for reset handled in GameProvider usually
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Game Reset Triggered')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    context,
                    'Reset Settings',
                    Icons.restore_rounded,
                    Colors.redAccent,
                    () => settings.resetSettings(),
                  ),
                  
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'LUDO AURA QUANTUM V1.0.0',
                      style: GoogleFonts.rajdhani(
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                        fontSize: 12,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: GoogleFonts.rajdhani(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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

  Widget _buildGlassContainer({required Widget child, Color? borderColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor ?? Colors.white.withValues(alpha: 0.1)),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.01),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildToggleSetting(BuildContext context, String title, IconData icon, bool value, Function(bool) onChanged) {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildGlassContainer(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: colorScheme.primary, size: 24),
        title: Text(
          title,
          style: GoogleFonts.rajdhani(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        trailing: Switch(
          value: value,
          activeColor: colorScheme.primary,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDropdownSetting<T>(BuildContext context, String title, IconData icon, T value, List<T> items, Function(T?) onChanged) {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildGlassContainer(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: colorScheme.primary, size: 24),
        title: Text(
          title,
          style: GoogleFonts.rajdhani(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        trailing: DropdownButton<T>(
          value: value,
          underline: const SizedBox(),
          dropdownColor: colorScheme.surface,
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                item.toString().split('.').last.toUpperCase(),
                style: GoogleFonts.rajdhani(fontWeight: FontWeight.w700),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return _buildGlassContainer(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: color, size: 24),
        title: Text(
          title,
          style: GoogleFonts.rajdhani(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.9),
            letterSpacing: 0.5,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPlayerCountSelector(BuildContext context, SettingsProvider settings) {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildGlassContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group_rounded, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Players',
                  style: GoogleFonts.rajdhani(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${settings.playerCount}',
                  style: GoogleFonts.orbitron(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [2, 3, 4].map((count) {
                final isSelected = settings.playerCount == count;
                return GestureDetector(
                  onTap: () => settings.setPlayerCount(count),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primary : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected ? [
                        BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 1)
                      ] : null,
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.orbitron(
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.black : colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildGlassContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_rounded, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Theme',
                  style: GoogleFonts.rajdhani(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ThemeType.values.map((type) {
                final isSelected = provider.themeType == type;
                String label = '';
                Color previewColor = Colors.white;
                switch(type) {
                  case ThemeType.darkNeon: label = 'NEON'; previewColor = const Color(0xFF00F2FF); break;
                  case ThemeType.brightAura: label = 'AURA'; previewColor = const Color(0xFFBD9CFF); break;
                  case ThemeType.classicBoard: label = 'CLASSIC'; previewColor = Colors.blue; break;
                }

                return GestureDetector(
                  onTap: () => provider.setTheme(type),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: previewColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? previewColor : Colors.white24,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: previewColor.withValues(alpha: 0.4), blurRadius: 15)
                          ] : null,
                        ),
                        child: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.circle,
                          color: isSelected ? previewColor : Colors.white24,
                          size: isSelected ? 32 : 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: GoogleFonts.rajdhani(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                          color: isSelected ? previewColor : colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
