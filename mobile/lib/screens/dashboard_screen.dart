import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import 'admin_approvals.dart';
import 'admin_payment_methods.dart';
import 'admin_orders_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/dashboard');
      if (res.statusCode == 200) {
        setState(() { _data = jsonDecode(res.body); _loading = false; });
        _animCtrl.forward(from: 0);
      }
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data == null) return _errorState();

    final total = (_data!['totalPayments'] ?? 0) as int;
    final unpaid = (_data!['unpaidPayments'] ?? 0) as int;
    final paid = total - unpaid;
    final rate = total > 0 ? paid / total : 0.0;
    final pendingMembers = (_data!['pendingMemberApprovals'] ?? 0) as int;
    final pendingPayments = (_data!['pendingPaymentApprovals'] ?? 0) as int;
    final totalPending = pendingMembers + pendingPayments;

    return RefreshIndicator(
      onRefresh: _load,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Hero collection card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF052e16), Color(0xFF14532d), Color(0xFF16a34a)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFF16a34a).withOpacity(0.3),
                    blurRadius: 20, offset: const Offset(0, 8))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Total Collected', style: GoogleFonts.outfit(
                      fontSize: 13, color: Colors.white.withOpacity(0.8))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(9999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.trending_up_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('${(rate * 100).round()}% rate',
                          style: GoogleFonts.outfit(fontSize: 11,
                              color: Colors.white, fontWeight: FontWeight.w600)),
                    ])),
                ]),
                const SizedBox(height: 8),
                Text(formatPeso(_data!['totalCollected']), style: GoogleFonts.outfit(
                    fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                ClipRRect(borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(
                    value: rate, minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white))),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('$paid paid', style: GoogleFonts.outfit(
                      fontSize: 12, color: Colors.white.withOpacity(0.8))),
                  Text('$unpaid pending', style: GoogleFonts.outfit(
                      fontSize: 12, color: Colors.white.withOpacity(0.8))),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            // Pending alert
            if (totalPending > 0) ...[
              _AlertCard(
                icon: Icons.notifications_active_rounded,
                color: Colors.orange,
                title: '$totalPending Pending Approval${totalPending > 1 ? 's' : ''}',
                subtitle: [
                  if (pendingMembers > 0) '$pendingMembers member application${pendingMembers > 1 ? 's' : ''}',
                  if (pendingPayments > 0) '$pendingPayments payment${pendingPayments > 1 ? 's' : ''}',
                ].join(' • '),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const AdminApprovalsScreen())).then((_) => _load()),
              ),
              const SizedBox(height: 16),
            ],

            // Stats grid
            _sectionLabel('Overview'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _StatCard('Food Items', '${_data!['totalFoodItems']}',
                    Icons.fastfood_rounded, const Color(0xFFf97316), const Color(0xFFfff7ed)),
                _StatCard('Members', '${_data!['totalMembers']}',
                    Icons.people_rounded, const Color(0xFF0ea5e9), const Color(0xFFf0f9ff)),
                _StatCard('Active', '${_data!['activeMembers']}',
                    Icons.person_pin_rounded, const Color(0xFF16a34a), const Color(0xFFf0fdf4)),
                _StatCard('Packages', '${_data!['totalPackages']}',
                    Icons.inventory_2_rounded, const Color(0xFF8b5cf6), const Color(0xFFfaf5ff)),
              ],
            ),
            const SizedBox(height: 20),

            // Quick actions
            _sectionLabel('Quick Actions'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _ActionCard(
                icon: Icons.how_to_reg_rounded,
                label: 'Approvals',
                subtitle: totalPending > 0 ? '$totalPending pending' : 'All clear',
                color: Colors.orange,
                badge: totalPending,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const AdminApprovalsScreen())).then((_) => _load()),
              )),
              const SizedBox(width: 12),
              Expanded(child: _ActionCard(
                icon: Icons.receipt_long_rounded,
                label: 'Orders',
                subtitle: 'Food orders',
                color: const Color(0xFFf43f5e),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const AdminOrdersScreen())),
              )),
            ]),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.payment_rounded,
              label: 'Payment Methods',
              subtitle: 'Manage GCash, Cash & more',
              color: const Color(0xFF16a34a),
              fullWidth: true,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const AdminPaymentMethodsScreen())),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label, style: GoogleFonts.outfit(
      fontSize: 13, fontWeight: FontWeight.w600,
      color: Colors.grey[600], letterSpacing: 0.3));

  Widget _errorState() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
        child: const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey)),
      const SizedBox(height: 16),
      Text('Could not load data', style: GoogleFonts.outfit(
          fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('Check your connection', style: GoogleFonts.outfit(color: Colors.grey)),
      const SizedBox(height: 20),
      ElevatedButton.icon(onPressed: _load,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text('Retry', style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
    ]));
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  const _StatCard(this.label, this.value, this.icon, this.color, this.bg);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a2e).withOpacity(0.8) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(
              color: isDark ? color.withOpacity(0.2) : bg,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
        const Spacer(),
        Text(value, style: GoogleFonts.outfit(
            fontSize: 26, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.outfit(
            fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;
  const _AlertCard({required this.icon, required this.color,
    required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25))),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          Text(subtitle, style: GoogleFonts.outfit(
              fontSize: 12, color: color.withOpacity(0.7))),
        ])),
        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
      ]),
    ),
  );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final int badge;
  final bool fullWidth;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label,
    required this.subtitle, required this.color, required this.onTap,
    this.badge = 0, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a1a2e).withOpacity(0.8) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          Stack(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22)),
            if (badge > 0) Positioned(right: 0, top: 0,
              child: Container(width: 16, height: 16,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Center(child: Text('$badge',
                    style: const TextStyle(fontSize: 9, color: Colors.white,
                        fontWeight: FontWeight.bold))))),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: GoogleFonts.outfit(
                fontSize: 11, color: Colors.grey[500])),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
        ]),
      ),
    );
  }
}
