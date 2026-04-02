import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import 'customer_packages.dart';
import 'customer_payments.dart';
import 'customer_profile.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _index = 0;
  String _username = '';
  String _userId = '';

  final _titles = ['Packages', 'My Payments', 'Profile'];

  @override
  void initState() {
    super.initState();
    AuthService.getUsername().then((u) => setState(() => _username = u));
    AuthService.getUserId().then((id) => setState(() => _userId = id));
  }

  List<Widget> get _screens => [
    const CustomerPackages(),
    CustomerPayments(userId: _userId),
    CustomerProfile(username: _username),
  ];

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _darkTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_index], style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          leading: Builder(builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          )),
        ),
        drawer: Drawer(
          child: SafeArea(child: Column(children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF14532d), Color(0xFF166534)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 64, height: 64,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/logo.jpg', fit: BoxFit.cover)),
                const SizedBox(height: 12),
                Text('Gia Store', style: GoogleFonts.outfit(fontSize: 18,
                    fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Customer Portal', style: GoogleFonts.outfit(fontSize: 12,
                    color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 8),
                Row(children: [
                  CircleAvatar(backgroundColor: Colors.white.withOpacity(0.2), radius: 12,
                    child: Text(_username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  Text(_username, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white)),
                ]),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 8), children: [
              _navItem(0, Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Packages'),
              _navItem(1, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'My Payments'),
              _navItem(2, Icons.person_outline, Icons.person_rounded, 'Profile'),
            ])),
            Padding(padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: Text('Logout', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.red.withOpacity(0.1),
                onTap: _logout,
              )),
          ])),
        ),
        body: _userId.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _screens[_index],
      ),
    );
  }

  Widget _navItem(int i, IconData icon, IconData selectedIcon, String label) {
    final selected = _index == i;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF16a34a).withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(selected ? selectedIcon : icon,
            color: selected ? const Color(0xFF4ade80) : Colors.grey[400], size: 22),
        title: Text(label, style: GoogleFonts.outfit(
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? const Color(0xFF4ade80) : Colors.grey[300])),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () { setState(() => _index = i); Navigator.pop(context); },
      ),
    );
  }

  ThemeData _darkTheme() => ThemeData(
    useMaterial3: true, brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF16a34a), brightness: Brightness.dark),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
    scaffoldBackgroundColor: const Color(0xFF0A1A0E),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0F2414),
        foregroundColor: Colors.white, elevation: 0, surfaceTintColor: Colors.transparent),
    cardTheme: CardThemeData(elevation: 0, color: const Color(0xFF1A2E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF0F2414)),
  );
}
