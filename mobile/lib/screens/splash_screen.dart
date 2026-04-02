import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'customer/customer_home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _logoScale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn);
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _logoCtrl.forward().then((_) => _textCtrl.forward());
    Future.delayed(const Duration(milliseconds: 2500), _init);
  }

  Future<void> _init() async {
    final info = await PackageInfo.fromPlatform();
    final update = await UpdateService.checkForUpdate(info.version);
    if (!mounted) return;
    if (update != null) { _showUpdateDialog(update); return; }
    _navigate();
  }

  void _showUpdateDialog(UpdateInfo update) {
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Update Available v${update.version}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(update.releaseNotes.isNotEmpty
            ? update.releaseNotes : 'A new version is available.',
            style: GoogleFonts.outfit(fontSize: 14)),
        actions: [
          TextButton(onPressed: _navigate,
              child: Text('Later', style: GoogleFonts.outfit(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => UpdateService.openDownload(update.downloadUrl),
            child: Text('Update', style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
        ],
      ));
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;
    final dest = !loggedIn
        ? const LoginScreen()
        : await AuthService.getRole() == 'ADMIN'
            ? const HomeScreen()
            : const CustomerHome();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => dest,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  void dispose() { _logoCtrl.dispose(); _textCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A2E14), Color(0xFF16a34a), Color(0xFF22c55e)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FadeTransition(opacity: _logoFade,
              child: ScaleTransition(scale: _logoScale,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3),
                          blurRadius: 30, offset: const Offset(0, 12)),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(opacity: _textFade,
              child: SlideTransition(position: _textSlide,
                child: Column(children: [
                  Text('Gia Foodies', style: GoogleFonts.outfit(
                      fontSize: 36, fontWeight: FontWeight.bold,
                      color: Colors.white, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text('Paluwagan & Food Store', style: GoogleFonts.outfit(
                      fontSize: 14, color: Colors.white.withOpacity(0.8))),
                ]),
              ),
            ),
            const SizedBox(height: 60),
            FadeTransition(opacity: _textFade,
              child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white.withOpacity(0.6), strokeWidth: 2),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
