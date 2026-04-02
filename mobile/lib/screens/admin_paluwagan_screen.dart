import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'members_screen.dart';
import 'payments_screen.dart';

class AdminPaluwaganScreen extends StatefulWidget {
  const AdminPaluwaganScreen({super.key});
  @override
  State<AdminPaluwaganScreen> createState() => _AdminPaluwaganScreenState();
}

class _AdminPaluwaganScreenState extends State<AdminPaluwaganScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: Theme.of(context).appBarTheme.backgroundColor,
        child: TabBar(
          controller: _tab,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          indicatorColor: const Color(0xFF16a34a),
          labelColor: const Color(0xFF16a34a),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.people_rounded, size: 18), text: 'Members'),
            Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'Payments'),
          ],
        ),
      ),
      Expanded(child: TabBarView(controller: _tab, children: const [
        MembersScreen(),
        PaymentsScreen(),
      ])),
    ]);
  }
}
