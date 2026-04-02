import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/dialogs.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _username = '';
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _isDark = ThemeService.instance.isDark;
    AuthService.getUsername().then((u) => setState(() => _username = u));
  }

  void _changePassword() {
    final _old = TextEditingController();
    final _new = TextEditingController();
    final _confirm = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Change Password', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ]),
          const SizedBox(height: 12),
          _passField(_old, 'Current Password'),
          const SizedBox(height: 10),
          _passField(_new, 'New Password'),
          const SizedBox(height: 10),
          _passField(_confirm, 'Confirm New Password'),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (_new.text != _confirm.text) {
                  showSnack(context, 'Passwords do not match', error: true); return;
                }
                if (_new.text.length < 6) {
                  showSnack(context, 'Password must be at least 6 characters', error: true); return;
                }
                final res = await ApiService.post('/auth/change-password', {
                  'username': _username,
                  'oldPassword': _old.text,
                  'newPassword': _new.text,
                });
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (res.statusCode == 200) showSnack(context, 'Password changed successfully ✓');
                else showSnack(context, 'Current password is incorrect', error: true);
              },
              child: Text('Update Password', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _changeUsername() {
    final _ctrl = TextEditingController(text: _username);
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Change Username', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ]),
          const SizedBox(height: 12),
          TextField(controller: _ctrl,
            decoration: InputDecoration(labelText: 'New Username', labelStyle: GoogleFonts.outfit(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2))),
            style: GoogleFonts.outfit()),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (_ctrl.text.isEmpty) return;
                final res = await ApiService.post('/auth/change-username', {
                  'oldUsername': _username, 'newUsername': _ctrl.text.trim(),
                });
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (res.statusCode == 200) {
                  await AuthService.updateUsername(_ctrl.text.trim());
                  setState(() => _username = _ctrl.text.trim());
                  showSnack(context, 'Username updated. Please login again.');
                  await Future.delayed(const Duration(seconds: 2));
                  await AuthService.logout();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                } else {
                  showSnack(context, 'Failed to update username', error: true);
                }
              },
              child: Text('Update Username', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _passField(TextEditingController ctrl, String label) {
    bool obscure = true;
    return StatefulBuilder(builder: (_, set) => TextField(
      controller: ctrl, obscureText: obscure,
      decoration: InputDecoration(labelText: label, labelStyle: GoogleFonts.outfit(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
          suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18),
              onPressed: () => set(() => obscure = !obscure))),
      style: GoogleFonts.outfit(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Profile section
        _sectionHeader('Account'),
        Card(child: Column(children: [
          ListTile(
            leading: CircleAvatar(backgroundColor: const Color(0xFF16a34a),
              child: Text(_username.isNotEmpty ? _username[0].toUpperCase() : 'A',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))),
            title: Text(_username, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            subtitle: Text('Administrator', style: GoogleFonts.outfit(fontSize: 12)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Color(0xFF16a34a)),
            title: Text('Change Username', style: GoogleFonts.outfit()),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: _changeUsername,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Color(0xFF16a34a)),
            title: Text('Change Password', style: GoogleFonts.outfit()),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: _changePassword,
          ),
        ])),
        const SizedBox(height: 16),

        // Appearance
        _sectionHeader('Appearance'),
        Card(child: Column(children: [
          SwitchListTile(
            secondary: Icon(_isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: const Color(0xFF16a34a)),
            title: Text('Dark Mode', style: GoogleFonts.outfit()),
            subtitle: Text(_isDark ? 'Dark theme enabled' : 'Light theme enabled',
                style: GoogleFonts.outfit(fontSize: 12)),
            value: _isDark,
            activeColor: const Color(0xFF16a34a),
            onChanged: (v) async {
              await ThemeService.instance.toggle();
              setState(() => _isDark = ThemeService.instance.isDark);
            },
          ),
        ])),
        const SizedBox(height: 16),

        // App info
        _sectionHeader('About'),
        Card(child: Column(children: [
          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFF16a34a)),
            title: Text('App Version', style: GoogleFonts.outfit()),
            trailing: Text('1.0.0', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.store_rounded, color: Color(0xFF16a34a)),
            title: Text('Gia Foodies', style: GoogleFonts.outfit()),
            subtitle: Text('Paluwagan & Food Store System', style: GoogleFonts.outfit(fontSize: 12)),
          ),
        ])),
        const SizedBox(height: 16),

        // Logout
        Card(child: ListTile(
          leading: const Icon(Icons.logout_rounded, color: Colors.red),
          title: Text('Logout', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w600)),
          onTap: () async {
            await AuthService.logout();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          },
        )),
      ]),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(title, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600,
        color: Colors.grey, letterSpacing: 0.5)),
  );
}
