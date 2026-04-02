import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    final ok = await AuthService.login(_userCtrl.text.trim(), _passCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username or password'),
            backgroundColor: Colors.red));
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16a34a),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.store_rounded, size: 44, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text('Gia Store',
                    style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Sign in to manage your store',
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                        blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _userCtrl,
                        decoration: _inputDec('Username', Icons.person_outline),
                        style: GoogleFonts.outfit(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: _inputDec('Password', Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        style: GoogleFonts.outfit(),
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16a34a),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _loading
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('Sign In',
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Default: admin / admin123',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.outfit(),
    prefixIcon: Icon(icon, color: const Color(0xFF16a34a)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2),
    ),
  );
}
