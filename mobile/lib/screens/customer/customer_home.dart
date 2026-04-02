import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/auth_service.dart';
import '../../services/update_service.dart';
import '../login_screen.dart';
import 'customer_dashboard.dart';
import 'customer_food_menu.dart';
import 'customer_packages.dart';
import 'customer_paluwagan.dart';
import 'customer_history.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _index = 0;
  String _username = '';
  String _userId = '';

  static const _bg = Color(0xFF060D07);
  static const _surface = Color(0xFF0F1A10);
  static const _card = Color(0xFF162018);
  static const _primary = Color(0xFF22c55e);
  static const _primaryDark = Color(0xFF16a34a);

  final _titles = ['Home', 'Food Menu', 'Packages', 'My Paluwagan', 'History'];
  final _navItems = [
    {'icon': Icons.home_outlined, 'sel': Icons.home_rounded, 'label': 'Home', 'color': Color(0xFF22c55e)},
    {'icon': Icons.restaurant_menu_outlined, 'sel': Icons.restaurant_menu_rounded, 'label': 'Food Menu', 'color': Color(0xFFf97316)},
    {'icon': Icons.inventory_2_outlined, 'sel': Icons.inventory_2_rounded, 'label': 'Packages', 'color': Color(0xFF8b5cf6)},
    {'icon': Icons.groups_outlined, 'sel': Icons.groups_rounded, 'label': 'My Paluwagan', 'color': Color(0xFF0ea5e9)},
    {'icon': Icons.history_rounded, 'sel': Icons.history_rounded, 'label': 'History', 'color': Color(0xFFf43f5e)},
  ];

  @override
  void initState() {
    super.initState();
    AuthService.getUsername().then((u) => setState(() => _username = u));
    AuthService.getUserId().then((id) => setState(() => _userId = id));
    Future.delayed(const Duration(seconds: 2), _checkUpdate);
  }

  Future<void> _checkUpdate() async {
    final info = await PackageInfo.fromPlatform();
    final update = await UpdateService.checkForUpdate(info.version);
    if (!mounted || update == null) return;
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Update Available v${update.version}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
      content: Text(update.releaseNotes.isNotEmpty
          ? update.releaseNotes : 'A new version is available.',
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[300])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Later', style: GoogleFonts.outfit(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _primaryDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () => UpdateService.openDownload(update.downloadUrl),
          child: Text('Update', style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
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

  List<Widget> get _screens => [
    CustomerDashboard(userId: _userId, username: _username),
    const CustomerFoodMenu(),
    const CustomerPackages(),
    CustomerPaluwagan(userId: _userId),
    CustomerHistory(userId: _userId),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _buildDarkTheme(),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _surface,
          elevation: 0,
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(_titles[_index], key: ValueKey(_index),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                    fontSize: 18, color: Colors.white)),
          ),
          leading: Builder(builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          )),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light),
        ),
        drawer: _buildDrawer(),
        body: _userId.isEmpty
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(key: ValueKey(_index), child: _screens[_index])),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 280,
      backgroundColor: _surface,
      child: Column(children: [
        // Header
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20, right: 20, bottom: 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF052e16), Color(0xFF0F2414), Color(0xFF14532d)],
              begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 52, height: 52,
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3),
                        blurRadius: 8, offset: const Offset(0, 4))]),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/logo.jpg', fit: BoxFit.cover)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Gia Foodies', style: GoogleFonts.outfit(fontSize: 18,
                    fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Customer Portal', style: GoogleFonts.outfit(
                    fontSize: 12, color: Colors.white.withOpacity(0.6))),
              ])),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: Row(children: [
                CircleAvatar(radius: 16,
                  backgroundColor: _primary.withOpacity(0.3),
                  child: Text(_username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                      style: GoogleFonts.outfit(fontSize: 14,
                          fontWeight: FontWeight.bold, color: _primary))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_username, style: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text('Customer', style: GoogleFonts.outfit(
                      fontSize: 11, color: Colors.grey[500])),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(9999)),
                  child: Text('MEMBER', style: GoogleFonts.outfit(
                      fontSize: 9, fontWeight: FontWeight.bold, color: _primary))),
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
                  splashColor: color.withOpacity(0.1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: selected ? Border.all(color: color.withOpacity(0.2)) : null),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: selected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10)),
                        child: Icon(
                          selected ? item['sel'] as IconData : item['icon'] as IconData,
                          color: selected ? color : Colors.grey[500], size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item['label'] as String,
                          style: GoogleFonts.outfit(
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 14,
                              color: selected ? color : Colors.grey[400]))),
                      if (selected)
                        Container(width: 6, height: 6,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    ]),
                  ),
                ),
              ),
            );
          }),
        ])),

        // Logout
        Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12,
              MediaQuery.of(context).padding.bottom + 12),
          child: Material(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _logout,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.15),
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

  ThemeData _buildDarkTheme() => ThemeData(
    useMaterial3: true, brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: _primaryDark, brightness: Brightness.dark,
        surface: _card),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
    scaffoldBackgroundColor: _bg,
    appBarTheme: const AppBarTheme(backgroundColor: _surface,
        foregroundColor: Colors.white, elevation: 0, surfaceTintColor: Colors.transparent),
    cardTheme: CardThemeData(elevation: 0, color: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    drawerTheme: const DrawerThemeData(backgroundColor: _surface),
    dividerColor: Colors.white.withOpacity(0.08),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: _card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2)),
      labelStyle: GoogleFonts.outfit(color: Colors.grey[500]),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: _primaryDark,
          foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
  );
}
