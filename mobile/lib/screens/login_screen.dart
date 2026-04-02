import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/dialogs.dart';
import 'home_screen.dart';
import 'customer/customer_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  // Login
  final _loginUser = TextEditingController();
  final _loginPass = TextEditingController();
  bool _loginObscure = true;
  // Register
  final _regName = TextEditingController();
  final _regPhone = TextEditingController();
  final _regUser = TextEditingController();
  final _regPass = TextEditingController();
  final _regConfirm = TextEditingController();
  bool _regObscure = true;
  bool _regConfirmObscure = true;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (_loginUser.text.isEmpty || _loginPass.text.isEmpty) {
      showSnack(context, 'Please fill in all fields', error: true); return;
    }
    setState(() => _loading = true);
    final result = await AuthService.login(
        _loginUser.text.trim(), _loginPass.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (result != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => result['role'] == 'ADMIN'
              ? const HomeScreen() : const CustomerHome()));
    } else {
      showSnack(context, 'Invalid username or password', error: true);
    }
  }

  Future<void> _register() async {
    if (_regName.text.isEmpty || _regUser.text.isEmpty || _regPass.text.isEmpty) {
      showSnack(context, 'Please fill in all required fields', error: true); return;
    }
    if (_regPass.text != _regConfirm.text) {
      showSnack(context, 'Passwords do not match', error: true); return;
    }
    if (_regPass.text.length < 6) {
      showSnack(context, 'Password must be at least 6 characters', error: true); return;
    }
    setState(() => _loading = true);
    final ok = await AuthService.register(_regUser.text.trim(),
        _regPass.text.trim(), _regName.text.trim(), _regPhone.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      showSnack(context, '🎉 Account created! Please login.');
      _tab.animateTo(0);
    } else {
      showSnack(context, 'Username already taken. Try another.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A2E14), Color(0xFF0F3D1A)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              const SizedBox(height: 32),
              // Logo
              Hero(tag: 'logo',
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3),
                        blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              Text('Gia Foodies', style: GoogleFonts.outfit(
                  fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Paluwagan & Food Store', style: GoogleFonts.outfit(
                  fontSize: 13, color: Colors.white.withOpacity(0.6))),
              const SizedBox(height: 32),

              // Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15),
                      blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: Column(children: [
                  // Tab bar
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: TabBar(
                      controller: _tab,
                      labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                      unselectedLabelStyle: GoogleFonts.outfit(fontSize: 15),
                      indicatorColor: const Color(0xFF16a34a),
                      indicatorWeight: 3,
                      labelColor: const Color(0xFF16a34a),
                      unselectedLabelColor: Colors.grey,
                      tabs: const [Tab(text: 'Sign In'), Tab(text: 'Register')],
                    ),
                  ),
                  // Forms
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: IndexedStack(
                      index: _tab.index,
                      children: [_loginForm(), _registerForm()],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _loginForm() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      _input(_loginUser, 'Username', Icons.person_outline),
      const SizedBox(height: 14),
      _passwordInput(_loginPass, 'Password', _loginObscure,
          () => setState(() => _loginObscure = !_loginObscure)),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _login,
          child: _loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Sign In', style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        )),
    ]),
  );

  Widget _registerForm() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      _input(_regName, 'Full Name *', Icons.badge_outlined),
      const SizedBox(height: 12),
      _input(_regPhone, 'Phone Number', Icons.phone_outlined,
          type: TextInputType.phone),
      const SizedBox(height: 12),
      _input(_regUser, 'Username *', Icons.alternate_email),
      const SizedBox(height: 12),
      _passwordInput(_regPass, 'Password *', _regObscure,
          () => setState(() => _regObscure = !_regObscure)),
      const SizedBox(height: 12),
      _passwordInput(_regConfirm, 'Confirm Password *', _regConfirmObscure,
          () => setState(() => _regConfirmObscure = !_regConfirmObscure)),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _register,
          child: _loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Create Account', style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        )),
    ]),
  );

  Widget _input(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) =>
      TextField(
        controller: ctrl, keyboardType: type,
        style: GoogleFonts.outfit(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF16a34a), size: 20),
          filled: true,
          fillColor: const Color(0xFFF0F7F0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
          labelStyle: GoogleFonts.outfit(color: Colors.grey[600]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  Widget _passwordInput(TextEditingController ctrl, String label,
      bool obscure, VoidCallback toggle) =>
      TextField(
        controller: ctrl,
        obscureText: obscure,
        style: GoogleFonts.outfit(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline,
              color: Color(0xFF16a34a), size: 20),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
                color: Colors.grey[500], size: 20),
            onPressed: toggle,
          ),
          filled: true,
          fillColor: const Color(0xFFF0F7F0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
          labelStyle: GoogleFonts.outfit(color: Colors.grey[600]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}
