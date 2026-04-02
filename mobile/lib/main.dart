import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await ThemeService.instance.init();
  runApp(const GiaFoodiesApp());
}

class GiaFoodiesApp extends StatefulWidget {
  const GiaFoodiesApp({super.key});
  @override
  State<GiaFoodiesApp> createState() => _GiaFoodiesAppState();
}

class _GiaFoodiesAppState extends State<GiaFoodiesApp> {
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
      title: 'Gia Foodies',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const primary = Color(0xFF16a34a);
    final bg = isDark ? const Color(0xFF0A0F0B) : const Color(0xFFF4F7F4);
    final card = isDark ? const Color(0xFF141F16) : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
          seedColor: primary, brightness: brightness, surface: card),
      textTheme: GoogleFonts.outfitTextTheme(
          ThemeData(brightness: brightness).textTheme),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F1A12),
        elevation: 0, surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F1A12)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: card,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: card),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E2E20) : const Color(0xFFF0F7F0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primary, width: 2)),
        labelStyle: GoogleFonts.outfit(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary, foregroundColor: Colors.white,
          elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}
