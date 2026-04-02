import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/update_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'food_screen.dart';
import 'packages_screen.dart';
import 'admin_paluwagan_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_approvals.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _index = 0;
  String _username = 'Admin';
  late AnimationController _drawerAnim;

  static const _primary = Color(0xFF16a34a);

  final _screens = const [
    DashboardScreen(), FoodScreen(), PackagesScreen(),
    AdminPaluwaganScreen(), AdminOrdersScreen(), AdminApprovalsScreen(),
  ];
  final _titles = ['Dashboard', 'Food Items', 'Packages', 'Paluwagan', 'Orders', 'Approvals'];
  final _navItems = [
    {'icon': Icons.dashboard_outlined, 'sel': Icons.dashboard_rounded, 'label': 'Dashboard', 'color': Color(0xFF16a34a)},
    {'icon': Icons.fastfood_outlined, 'sel': Icons.fastfood_rounded, 'label': 'Food Items', 'color': Color(0xFFf97316)},
    {'icon': Icons.inventory_2_outlined, 'sel': Icons.inventory_2_rounded, 'label': 'Packages', 'color': Color(0xFF8b5cf6)},
    {'icon': Icons.groups_outlined, 'sel': Icons.groups_rounded, 'label': 'Paluwagan', 'color': Color(0xFF0ea5e9)},
    {'icon': Icons.receipt_long_outlined, 'sel': Icons.receipt_long_rounded, 'label': 'Orders', 'color': Color(0xFFf43f5e)},
    {'icon': Icons.how_to_reg_outlined, 'sel': Icons.how_to_reg_rounded, 'label': 'Approvals', 'color': Color(0xFFf97316)},
  ];

  @override
  void initState() {
    super.initState();
    _drawerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    AuthService.getUsername().then((u) => setState(() => _username = u));
    Future.delayed(const Duration(seconds: 2), _checkUpdate);
  }

  @override
  void dispose() { _drawerAnim.dispose(); super.dispose(); }

  Future<void> _checkUpdate() async {
    final info = await PackageInfo.fromPlatform();
    final update = await UpdateService.checkForUpdate(info.version);
    if (!mounted || update == null) return;
    _showUpdateDialog(update);
  }

  void _showUpdateDialog(UpdateInfo update) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.system_update_rounded, color: _primary, size: 20)),
        const SizedBox(width: 10),
        Text('Update Available', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Version ${update.version} is ready',
            style: GoogleFonts.outfit(color: Colors.grey[600])),
        if (update.releaseNotes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(update.releaseNotes, style: GoogleFonts.outfit(fontSize: 13)),
        ],
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Later', style: GoogleFonts.outfit(color: Colors.grey))),
        ElevatedButton.icon(
          icon: const Icon(Icons.download_rounded, size: 16),
          label: Text('Update Now', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () => UpdateService.openDownload(update.downloadUrl)),
      ],
    ));
  }

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _navigate(int i) {
    setState(() => _index = i);
    Navigator.pop(context);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(_titles[_index], key: ValueKey(_index),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        leading: Builder(builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, size: 24),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        )),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  key: ValueKey(isDark), size: 22)),
            onPressed: () => ThemeService.instance.toggle(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: _buildDrawer(theme, isDark),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(key: ValueKey(_index), child: _screens[_index]),
      ),
    );
  }

  Widget _buildDrawer(ThemeData theme, bool isDark) {
    return Drawer(
      width: 280,
      child: Column(children: [
        // Header with gradient
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20, right: 20, bottom: 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF052e16), Color(0xFF14532d), Color(0xFF16a34a)],
              begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 52, height: 52,
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2),
                        blurRadius: 8, offset: const Offset(0, 4))]),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/logo.jpg', fit: BoxFit.cover)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Gia Foodies', style: GoogleFonts.outfit(fontSize: 18,
                    fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Admin Panel', style: GoogleFonts.outfit(
                    fontSize: 12, color: Colors.white.withOpacity(0.7))),
              ])),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                CircleAvatar(radius: 16, backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(_username.isNotEmpty ? _username[0].toUpperCase() : 'A',
                      style: GoogleFonts.outfit(fontSize: 14,
                          fontWeight: FontWeight.bold, color: Colors.white))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_username, style: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text('Administrator', style: GoogleFonts.outfit(
                      fontSize: 11, color: Colors.white.withOpacity(0.6))),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(9999)),
                  child: Text('ADMIN', style: GoogleFonts.outfit(
                      fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white))),
              ]),
            ),
          ]),
        ),

        // Nav items
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 0), children: [
          ...List.generate(_navItems.length, (i) {
            final item = _navItems[i];
            final selected = _index == i;
            final color = item['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _navigate(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: selected ? Border.all(color: color.withOpacity(0.25)) : null,
                    ),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: selected ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10)),
                        child: Icon(
                          selected ? item['sel'] as IconData : item['icon'] as IconData,
                          color: selected ? color : Colors.grey[500], size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item['label'] as String,
                          style: GoogleFonts.outfit(
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 14,
                              color: selected ? color : null))),
                      if (selected)
                        Container(width: 6, height: 6,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    ]),
                  ),
                ),
              ),
            );
          }),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1)),
          _drawerAction(Icons.settings_outlined, 'Settings', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
        ])),

        // Logout
        Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12,
              MediaQuery.of(context).padding.bottom + 12),
          child: Material(
            color: Colors.red.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _logout,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20)),
                  const SizedBox(width: 12),
                  Text('Logout', style: GoogleFonts.outfit(
                      color: Colors.red, fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _drawerAction(IconData icon, String label, VoidCallback onTap) =>
      Material(color: Colors.transparent, borderRadius: BorderRadius.circular(14),
        child: InkWell(borderRadius: BorderRadius.circular(14), onTap: onTap,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.grey[500], size: 20)),
              const SizedBox(width: 12),
              Text(label, style: GoogleFonts.outfit(fontSize: 14)),
            ]))));
}
