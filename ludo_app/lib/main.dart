import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'providers/game_provider.dart';
import 'providers/settings_provider.dart';
import 'utils/aura_feedback.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const LudoAuraQuantumApp(),
    ),
  );
}

class LudoAuraQuantumApp extends StatelessWidget {
  const LudoAuraQuantumApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => AuraFeedback.playTouch(),
      child: MaterialApp(
        title: 'Ludo Aura Quantum',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
          primaryColor: const Color(0xFF00FFCC),
          materialTapTargetSize: MaterialTapTargetSize.padded,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00FFCC),
            brightness: Brightness.dark,
            primary: const Color(0xFF00FFCC),
            secondary: const Color(0xFFFF0055),
            surface: const Color(0xFF121212),
          ),
          textTheme: GoogleFonts.orbitronTextTheme(
            ThemeData.dark().textTheme,
          ),
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Ludo Aura Quantum V2'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
          ),
          body: const HomeScreen(),
        ),
      ),
    );
  }
}
