import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await ThemeService.instance.init();
  runApp(const GiaStoreApp());
}

class GiaStoreApp extends StatefulWidget {
  const GiaStoreApp({super.key});
  @override
  State<GiaStoreApp> createState() => _GiaStoreAppState();
}

class _GiaStoreAppState extends State<GiaStoreApp> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onThemeChanged);
  }

  void _onThemeChanged() => setState(() {});

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      title: 'Gia Store',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = const Color(0xFF16a34a);
    final bg = isDark ? const Color(0xFF0F1A12) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1A2E1E) : Colors.white;
    final surface = isDark ? const Color(0xFF1A2E1E) : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: brightness, surface: surface),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData(brightness: brightness).textTheme),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1e293b),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: card,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: card),
    );
  }
}
