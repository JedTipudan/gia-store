import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/dialogs.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _loginUser = TextEditingController();
  final _loginPass = TextEditingController();
  final _regUser = TextEditingController();
  final _regPass = TextEditingController();
  final _regConfirm = TextEditingController();
  bool _loading = false;
  bool _obscure1 = true, _obscure2 = true, _obscure3 = true;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (_loginUser.text.isEmpty || _loginPass.text.isEmpty) return;
    setState(() => _loading = true);
    final ok = await AuthService.login(_loginUser.text.trim(), _loginPass.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      showSnack(context, 'Invalid username or password', error: true);
    }
  }

  Future<void> _register() async {
    if (_regUser.text.isEmpty || _regPass.text.isEmpty) return;
    if (_regPass.text != _regConfirm.text) {
      showSnack(context, 'Passwords do not match', error: true); return;
    }
    setState(() => _loading = true);
    final ok = await AuthService.register(_regUser.text.trim(), _regPass.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      showSnack(context, 'Account created! Please login.');
      _tab.animateTo(0);
    } else {
      showSnack(context, 'Registration failed. Username may already exist.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1),
                        blurRadius: 10, offset: const Offset(0, 4))]),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
              ),
              const SizedBox(height: 14),
              Text('Gia Store', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Paluwagan & Food Store System',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                        blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(children: [
                  TabBar(
                    controller: _tab,
                    labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    unselectedLabelStyle: GoogleFonts.outfit(),
                    indicatorColor: const Color(0xFF16a34a),
                    labelColor: const Color(0xFF16a34a),
                    unselectedLabelColor: Colors.grey,
                    tabs: const [Tab(text: 'Login'), Tab(text: 'Register')],
                  ),
                  SizedBox(
                    height: 280,
                    child: TabBarView(controller: _tab, children: [
                      _loginForm(),
                      _registerForm(),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _loginForm() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      _field(_loginUser, 'Username', Icons.person_outline),
      const SizedBox(height: 12),
      _passField(_loginPass, 'Password', _obscure1, () => setState(() => _obscure1 = !_obscure1)),
      const SizedBox(height: 20),
      _submitBtn('Sign In', _login),
      const SizedBox(height: 8),
      Text('Default: admin / admin123', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
    ]),
  );

  Widget _registerForm() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      _field(_regUser, 'Username', Icons.person_outline),
      const SizedBox(height: 10),
      _passField(_regPass, 'Password', _obscure2, () => setState(() => _obscure2 = !_obscure2)),
      const SizedBox(height: 10),
      _passField(_regConfirm, 'Confirm Password', _obscure3, () => setState(() => _obscure3 = !_obscure3)),
      const SizedBox(height: 16),
      _submitBtn('Create Account', _register),
    ]),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon) =>
      TextField(controller: ctrl,
          decoration: InputDecoration(labelText: label, labelStyle: GoogleFonts.outfit(),
              prefixIcon: Icon(icon, color: const Color(0xFF16a34a), size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
          style: GoogleFonts.outfit());

  Widget _passField(TextEditingController ctrl, String label, bool obscure, VoidCallback toggle) =>
      TextField(controller: ctrl, obscureText: obscure,
          decoration: InputDecoration(labelText: label, labelStyle: GoogleFonts.outfit(),
              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF16a34a), size: 20),
              suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                  onPressed: toggle),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
          style: GoogleFonts.outfit(),
          onSubmitted: (_) => label == 'Password' ? _login() : null);

  Widget _submitBtn(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity, height: 44,
    child: ElevatedButton(
      onPressed: _loading ? null : onTap,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: _loading ? const SizedBox(width: 18, height: 18,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
    ),
  );
}
