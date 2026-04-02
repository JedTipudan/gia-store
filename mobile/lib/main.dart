import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const GiaStoreApp());
}

class GiaStoreApp extends StatelessWidget {
  const GiaStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return MaterialApp(
      title: 'Gia Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF16a34a)),
        textTheme: GoogleFonts.outfitTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1e293b),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: const Color(0xFFDCFCE7),
          iconTheme: WidgetStateProperty.resolveWith((states) =>
              IconThemeData(color: states.contains(WidgetState.selected)
                  ? const Color(0xFF16a34a) : Colors.grey)),
          labelTextStyle: WidgetStateProperty.resolveWith((states) =>
              GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600,
                  color: states.contains(WidgetState.selected)
                      ? const Color(0xFF16a34a) : Colors.grey)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
