import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'food_screen.dart';
import 'packages_screen.dart';
import 'members_screen.dart';
import 'payments_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  String _username = 'Admin';

  final _screens = const [
    DashboardScreen(),
    FoodScreen(),
    PackagesScreen(),
    MembersScreen(),
    PaymentsScreen(),
  ];

  final _titles = ['Dashboard', 'Food Items', 'Packages', 'Members', 'Payments'];

  final _navItems = const [
    {'icon': Icons.dashboard_outlined, 'selectedIcon': Icons.dashboard_rounded, 'label': 'Dashboard'},
    {'icon': Icons.fastfood_outlined, 'selectedIcon': Icons.fastfood_rounded, 'label': 'Food Items'},
    {'icon': Icons.inventory_2_outlined, 'selectedIcon': Icons.inventory_2_rounded, 'label': 'Packages'},
    {'icon': Icons.people_outline, 'selectedIcon': Icons.people_rounded, 'label': 'Members'},
    {'icon': Icons.receipt_long_outlined, 'selectedIcon': Icons.receipt_long_rounded, 'label': 'Payments'},
  ];

  @override
  void initState() {
    super.initState();
    AuthService.getUsername().then((u) => setState(() => _username = u));
  }

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDark;
    final primary = const Color(0xFF16a34a);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: Builder(builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        )),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => ThemeService.instance.toggle(),
            tooltip: 'Toggle dark mode',
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, const Color(0xFF15803d)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  Container(width: 56, height: 56,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16)),
                    child: Stack(alignment: Alignment.center, children: [
                      const Icon(Icons.storefront_rounded, size: 32, color: Colors.white),
                      Positioned(bottom: 6, right: 6,
                        child: Container(width: 18, height: 18,
                          decoration: const BoxDecoration(color: Color(0xFFfbbf24), shape: BoxShape.circle),
                          child: const Icon(Icons.currency_exchange, size: 10, color: Colors.white))),
                    ])),
                ]),
                const SizedBox(height: 12),
                Text('Gia Store', style: GoogleFonts.outfit(fontSize: 20,
                    fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Paluwagan & Food Store', style: GoogleFonts.outfit(
                    fontSize: 12, color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 8),
                Row(children: [
                  CircleAvatar(backgroundColor: Colors.white.withOpacity(0.3), radius: 12,
                    child: Text(_username[0].toUpperCase(),
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
                  const SizedBox(width: 8),
                  Text(_username, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white)),
                ]),
              ]),
            ),
            const SizedBox(height: 8),
            // Nav items
            Expanded(
              child: ListView(padding: const EdgeInsets.symmetric(horizontal: 8), children: [
                ..._navItems.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  final selected = _index == i;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: selected ? primary.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        selected ? item['selectedIcon'] as IconData : item['icon'] as IconData,
                        color: selected ? primary : null, size: 22),
                      title: Text(item['label'] as String,
                          style: GoogleFonts.outfit(fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              color: selected ? primary : null)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () {
                        setState(() => _index = i);
                        Navigator.pop(context);
                      },
                      selected: selected,
                    ),
                  );
                }),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.settings_outlined, size: 22),
                  title: Text('Settings', style: GoogleFonts.outfit()),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                ),
              ]),
            ),
            // Logout
            Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
                title: Text('Logout', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w600)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.red.withOpacity(0.08),
                onTap: _logout,
              ),
            ),
          ]),
        ),
      ),
      body: _screens[_index],
    );
  }
}
