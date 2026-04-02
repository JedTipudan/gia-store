import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../widgets/app_icon.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), _init);
  }

  Future<void> _init() async {
    final info = await PackageInfo.fromPlatform();
    final update = await UpdateService.checkForUpdate(info.version);
    if (!mounted) return;
    if (update != null) { _showUpdateDialog(update); return; }
    _navigate();
  }

  void _showUpdateDialog(UpdateInfo update) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Update Available v${update.version}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(update.releaseNotes.isNotEmpty ? update.releaseNotes
            : 'A new version is available.', style: GoogleFonts.outfit(fontSize: 14)),
        actions: [
          TextButton(onPressed: _navigate,
              child: Text('Later', style: GoogleFonts.outfit(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => UpdateService.openDownload(update.downloadUrl),
            child: Text('Update', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => loggedIn ? const HomeScreen() : const LoginScreen(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16a34a),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Stack(alignment: Alignment.center, children: [
                  const Icon(Icons.storefront_rounded, size: 56, color: Colors.white),
                  Positioned(
                    bottom: 8, right: 8,
                    child: Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(color: Color(0xFFfbbf24), shape: BoxShape.circle),
                      child: const Icon(Icons.currency_exchange, size: 16, color: Colors.white),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              Text('Gia Store', style: GoogleFonts.outfit(
                  fontSize: 34, fontWeight: FontWeight.bold,
                  color: Colors.white, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text('Paluwagan & Food Store System',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withOpacity(0.85))),
            ]),
          ),
        ),
      ),
    );
  }
}
