import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ThemeType { darkNeon, brightAura, classicBoard }

class ThemeProvider extends ChangeNotifier {
  ThemeType _themeType = ThemeType.darkNeon;

  ThemeType get themeType => _themeType;

  ThemeData get currentTheme {
    switch (_themeType) {
      case ThemeType.darkNeon:
        return _darkNeonTheme;
      case ThemeType.brightAura:
        return _brightAuraTheme;
      case ThemeType.classicBoard:
        return _classicBoardTheme;
    }
  }

  void setTheme(ThemeType type) {
    _themeType = type;
    notifyListeners();
  }

  static final ThemeData _darkNeonTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF090B10),
    primaryColor: const Color(0xFF00F2FF),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00F2FF),
      secondary: Color(0xFFFF00E5),
      surface: Color(0xFF11161D),
      surfaceContainer: Color(0xFF171D26),
    ),
    textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme),
  );

  static final ThemeData _brightAuraTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0916),
    primaryColor: const Color(0xFFBD9CFF),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFBD9CFF),
      secondary: Color(0xFF41D9C3),
      surface: Color(0xFF1D1429),
      surfaceContainer: Color(0xFF251A36),
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
  );

  static final ThemeData _classicBoardTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    primaryColor: Colors.blue,
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.red,
      surface: Colors.white,
      surfaceContainer: Color(0xFFE0E0E0),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
  );
}
