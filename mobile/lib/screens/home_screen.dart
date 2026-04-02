import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'food_screen.dart';
import 'packages_screen.dart';
import 'members_screen.dart';
import 'payments_screen.dart';

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

  @override
  void initState() {
    super.initState();
    AuthService.getUsername().then((u) => setState(() => _username = u));
  }

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index],
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton(
              child: CircleAvatar(
                backgroundColor: const Color(0xFF16a34a),
                radius: 16,
                child: Text(_username[0].toUpperCase(),
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  child: Text(_username, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  enabled: false,
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  onTap: _logout,
                  child: Row(children: [
                    const Icon(Icons.logout, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Logout', style: GoogleFonts.outfit(color: Colors.red)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.shopping_basket_outlined),
              selectedIcon: Icon(Icons.shopping_basket), label: 'Food'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2), label: 'Packages'),
          NavigationDestination(icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people), label: 'Members'),
          NavigationDestination(icon: Icon(Icons.payment_outlined),
              selectedIcon: Icon(Icons.payment), label: 'Payments'),
        ],
      ),
    );
  }
}
