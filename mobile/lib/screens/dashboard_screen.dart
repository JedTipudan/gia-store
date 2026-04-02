import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import 'admin_approvals.dart';
import 'admin_payment_methods.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/dashboard');
      if (res.statusCode == 200) setState(() { _data = jsonDecode(res.body); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data == null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
      const SizedBox(height: 8),
      Text('Could not load data', style: GoogleFonts.outfit(color: Colors.grey)),
      TextButton(onPressed: _load, child: const Text('Retry')),
    ]));

    final total = (_data!['totalPayments'] ?? 0) as int;
    final unpaid = (_data!['unpaidPayments'] ?? 0) as int;
    final paid = total - unpaid;
    final rate = total > 0 ? paid / total : 0.0;
    final pendingMembers = (_data!['pendingMemberApprovals'] ?? 0) as int;
    final pendingPayments = (_data!['pendingPaymentApprovals'] ?? 0) as int;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Pending approvals alert
          if (pendingMembers > 0 || pendingPayments > 0)
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminApprovalsScreen())).then((_) => _load()),
              child: Container(
                width: double.infinity, margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.notifications_active_rounded, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pending Approvals', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.orange)),
                    Text('${pendingMembers > 0 ? "$pendingMembers member application(s)" : ""}${pendingMembers > 0 && pendingPayments > 0 ? " • " : ""}${pendingPayments > 0 ? "$pendingPayments payment(s)" : ""} need your review',
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange.withOpacity(0.8))),
                  ])),
                  const Icon(Icons.chevron_right, color: Colors.orange),
                ]),
              ),
            ),

          Text('Overview', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
            children: [
              _StatCard('Food Items', '${_data!['totalFoodItems']}', Icons.fastfood_rounded, const Color(0xFF16a34a), const Color(0xFFDCFCE7)),
              _StatCard('Total Members', '${_data!['totalMembers']}', Icons.people_rounded, const Color(0xFF2563eb), const Color(0xFFDBEAFE)),
              _StatCard('Active Members', '${_data!['activeMembers']}', Icons.person_pin_rounded, const Color(0xFFd97706), const Color(0xFFFEF3C7)),
              _StatCard('Packages', '${_data!['totalPackages']}', Icons.inventory_2_rounded, const Color(0xFF7c3aed), const Color(0xFFEDE9FE)),
            ],
          ),
          const SizedBox(height: 16),

          // Collection card
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.trending_up, color: Color(0xFF16a34a), size: 18),
                const SizedBox(width: 8),
                Text('Total Collected', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              Text(formatPeso(_data!['totalCollected']), style: GoogleFonts.outfit(
                  fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF16a34a))),
              Text('$paid of $total payments collected', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(9999),
                child: LinearProgressIndicator(value: rate, minHeight: 8,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF16a34a)))),
              const SizedBox(height: 4),
              Text('${(rate * 100).round()}% collection rate', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500])),
            ])),
          const SizedBox(height: 12),

          // Quick actions
          Text('Quick Actions', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _QuickAction('Approvals', Icons.how_to_reg_rounded, Colors.orange,
                badge: pendingMembers + pendingPayments,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const AdminApprovalsScreen())).then((_) => _load()))),
            const SizedBox(width: 12),
            Expanded(child: _QuickAction('Payment Methods', Icons.payment_rounded, const Color(0xFF16a34a),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const AdminPaymentMethodsScreen())))),
          ]),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  const _StatCard(this.label, this.value, this.icon, this.color, this.bg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20)),
      const Spacer(),
      Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
    ]),
  );
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int badge;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.color, {required this.onTap, this.badge = 0});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Stack(children: [
          Icon(icon, color: color, size: 28),
          if (badge > 0) Positioned(right: 0, top: 0,
            child: Container(width: 14, height: 14,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Center(child: Text('$badge', style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold))))),
        ]),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: color))),
        Icon(Icons.chevron_right, color: color, size: 18),
      ]),
    ),
  );
}
