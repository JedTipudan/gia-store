import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/dialogs.dart';
import '../login_screen.dart';

class CustomerProfile extends StatefulWidget {
  final String username;
  const CustomerProfile({super.key, required this.username});
  @override
  State<CustomerProfile> createState() => _CustomerProfileState();
}

class _CustomerProfileState extends State<CustomerProfile> {
  Map? _profile;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await ApiService.get('/auth/profile/${widget.username}');
    if (res.statusCode == 200) setState(() { _profile = jsonDecode(res.body); _loading = false; });
  }

  void _editProfile() {
    final _name = TextEditingController(text: _profile?['fullName'] ?? '');
    final _phone = TextEditingController(text: _profile?['phone'] ?? '');
    final _email = TextEditingController(text: _profile?['email'] ?? '');
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Edit Profile', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
          ]),
          const SizedBox(height: 12),
          _darkField(_name, 'Full Name', Icons.person_outline),
          const SizedBox(height: 10),
          _darkField(_phone, 'Phone', Icons.phone_outlined, type: TextInputType.phone),
          const SizedBox(height: 10),
          _darkField(_email, 'Email', Icons.email_outlined, type: TextInputType.emailAddress),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                final res = await ApiService.put('/auth/profile/${widget.username}',
                    {'fullName': _name.text, 'phone': _phone.text, 'email': _email.text});
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (res.statusCode == 200) { showSnack(context, 'Profile updated!'); _load(); }
                else showSnack(context, 'Failed to update', error: true);
              },
              child: Text('Save Changes', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)))),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _darkField(TextEditingController c, String l, IconData icon, {TextInputType type = TextInputType.text}) =>
      TextField(controller: c, keyboardType: type, style: GoogleFonts.outfit(color: Colors.white),
          decoration: InputDecoration(labelText: l, labelStyle: GoogleFonts.outfit(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: const Color(0xFF4ade80), size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[700]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF4ade80), width: 2))));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(padding: const EdgeInsets.all(16), children: [
      Center(child: Column(children: [
        CircleAvatar(radius: 40, backgroundColor: const Color(0xFF16a34a),
          child: Text((_profile?['fullName'] ?? widget.username)[0].toUpperCase(),
              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))),
        const SizedBox(height: 12),
        Text(_profile?['fullName'] ?? widget.username,
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text('@${widget.username}', style: GoogleFonts.outfit(color: Colors.grey[400])),
        const SizedBox(height: 4),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF16a34a).withOpacity(0.2),
              borderRadius: BorderRadius.circular(9999)),
          child: Text('Customer', style: GoogleFonts.outfit(fontSize: 12,
              color: const Color(0xFF4ade80), fontWeight: FontWeight.w600))),
      ])),
      const SizedBox(height: 24),
      Card(child: Column(children: [
        _infoTile(Icons.phone_outlined, 'Phone', _profile?['phone'] ?? 'Not set'),
        const Divider(height: 1),
        _infoTile(Icons.email_outlined, 'Email', _profile?['email'] ?? 'Not set'),
      ])),
      const SizedBox(height: 12),
      Card(child: ListTile(
        leading: const Icon(Icons.edit_outlined, color: Color(0xFF4ade80)),
        title: Text('Edit Profile', style: GoogleFonts.outfit(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: _editProfile,
      )),
      const SizedBox(height: 8),
      Card(child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        title: Text('Logout', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w600)),
        onTap: () async {
          await AuthService.logout();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
        },
      )),
    ]);
  }

  Widget _infoTile(IconData icon, String label, String value) => ListTile(
    leading: Icon(icon, color: const Color(0xFF4ade80), size: 20),
    title: Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400])),
    subtitle: Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500)),
  );
}
