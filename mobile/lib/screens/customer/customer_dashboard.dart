import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';

class CustomerDashboard extends StatefulWidget {
  final String userId;
  final String username;
  const CustomerDashboard({super.key, required this.userId, required this.username});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard>
    with SingleTickerProviderStateMixin {
  List _members = [];
  List _payments = [];
  List _orders = [];
  bool _loading = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _primary = Color(0xFF22c55e);
  static const _card = Color(0xFF162018);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    if (widget.userId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final mRes = await ApiService.get('/paluwagan/members/user/${widget.userId}');
      final pRes = await ApiService.get('/paluwagan/payments/user/${widget.userId}');
      final oRes = await ApiService.get('/orders/user/${widget.userId}');
      setState(() {
        _members = mRes.statusCode == 200 ? jsonDecode(mRes.body) : [];
        _payments = pRes.statusCode == 200 ? jsonDecode(pRes.body) : [];
        _orders = oRes.statusCode == 200 ? jsonDecode(oRes.body) : [];
        _loading = false;
      });
      _animCtrl.forward(from: 0);
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(
        child: CircularProgressIndicator(color: _primary));

    final activeEnrollments = _members.where((m) => m['status'] == 'ACTIVE').toList();
    final pendingEnrollments = _members.where((m) => m['status'] == 'PENDING').toList();
    final totalPayments = _payments.length;
    final paidPayments = _payments.where((p) => p['paid'] == true).length;
    final submittedPayments = _payments.where((p) =>
        p['approvalStatus'] == 'SUBMITTED').length;
    final unpaidPayments = _payments.where((p) =>
        p['paid'] == false && p['approvalStatus'] == 'PENDING').length;
    final totalPaid = _payments.where((p) => p['paid'] == true)
        .fold(0.0, (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble());
    final progress = totalPayments > 0 ? paidPayments / totalPayments : 0.0;
    final pendingOrders = _orders.where((o) =>
        o['status'] == 'PENDING' || o['status'] == 'SUBMITTED').length;
    final confirmedOrders = _orders.where((o) => o['status'] == 'CONFIRMED').length;
    final totalPending = pendingOrders + submittedPayments;

    return RefreshIndicator(
      onRefresh: _load,
      color: _primary,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Hero welcome card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF052e16), Color(0xFF0F2414), Color(0xFF14532d)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: const Color(0xFF16a34a).withOpacity(0.25),
                    blurRadius: 20, offset: const Offset(0, 8))]),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hello,', style: GoogleFonts.outfit(
                      fontSize: 14, color: Colors.white.withOpacity(0.7))),
                  Text(widget.username, style: GoogleFonts.outfit(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9999)),
                    child: Text(
                      activeEnrollments.isEmpty
                          ? '🌱 No active paluwagan yet'
                          : '✅ ${activeEnrollments.length} active enrollment${activeEnrollments.length > 1 ? 's' : ''}',
                      style: GoogleFonts.outfit(fontSize: 12,
                          color: Colors.white, fontWeight: FontWeight.w500)),
                  ),
                ])),
                Container(width: 60, height: 60,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2))),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/logo.jpg', fit: BoxFit.cover)),
              ]),
            ),
            const SizedBox(height: 16),

            // Pending alert
            if (totalPending > 0) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.withOpacity(0.25))),
                child: Row(children: [
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.notifications_active_rounded,
                        color: Colors.orange, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$totalPending pending action${totalPending > 1 ? 's' : ''}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                            color: Colors.orange, fontSize: 13)),
                    Text([
                      if (pendingOrders > 0) '$pendingOrders food order${pendingOrders > 1 ? 's' : ''}',
                      if (submittedPayments > 0) '$submittedPayments payment${submittedPayments > 1 ? 's' : ''} submitted',
                    ].join(' • '),
                        style: GoogleFonts.outfit(fontSize: 11,
                            color: Colors.orange.withOpacity(0.8))),
                  ])),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // Paluwagan stats
            _sectionLabel('Paluwagan'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _StatTile('Total Paid', formatPeso(totalPaid),
                  Icons.payments_rounded, _primary)),
              const SizedBox(width: 10),
              Expanded(child: _StatTile('Progress',
                  '$paidPayments / $totalPayments',
                  Icons.receipt_long_rounded, Colors.blue[300]!)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _StatTile('Submitted',
                  '$submittedPayments', Icons.hourglass_empty_rounded, Colors.orange)),
              const SizedBox(width: 10),
              Expanded(child: _StatTile('Unpaid',
                  '$unpaidPayments', Icons.warning_amber_rounded, Colors.red[300]!)),
            ]),

            if (totalPayments > 0) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _card,
                    borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Payment Progress', style: GoogleFonts.outfit(
                        fontSize: 12, color: Colors.grey[400])),
                    Text('${(progress * 100).round()}%',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                            color: _primary, fontSize: 14)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(
                      value: progress, minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: const AlwaysStoppedAnimation(_primary))),
                ])),
            ],
            const SizedBox(height: 20),

            // Food orders
            _sectionLabel('Food Orders'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _StatTile('Confirmed', '$confirmedOrders',
                  Icons.check_circle_rounded, _primary)),
              const SizedBox(width: 10),
              Expanded(child: _StatTile('Pending', '$pendingOrders',
                  Icons.pending_rounded, Colors.orange)),
            ]),
            const SizedBox(height: 20),

            // Active enrollments
            if (activeEnrollments.isNotEmpty) ...[
              _sectionLabel('Active Enrollments'),
              const SizedBox(height: 10),
              ...activeEnrollments.map((m) {
                final memberPayments = _payments
                    .where((p) => p['member']?['id'] == m['id']).toList();
                final memberPaid = memberPayments.where((p) => p['paid'] == true).length;
                final memberTotal = memberPayments.length;
                final nextUnpaid = memberPayments.where((p) =>
                    p['paid'] == false && p['approvalStatus'] == 'PENDING').toList();
                final memberProgress = memberTotal > 0 ? memberPaid / memberTotal : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _primary.withOpacity(0.2))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Text(m['paluwaganPackage']?['name'] ?? '',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                              color: Colors.white, fontSize: 15))),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: _primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(9999)),
                        child: Text('ACTIVE', style: GoogleFonts.outfit(
                            fontSize: 9, fontWeight: FontWeight.bold, color: _primary))),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.payments_outlined, size: 13, color: Color(0xFF22c55e)),
                      const SizedBox(width: 4),
                      Text('${formatPeso(m['paluwaganPackage']?['weeklyAmount'])}/week',
                          style: GoogleFonts.outfit(color: _primary,
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Since ${formatDate(m['startDate'])}',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500])),
                    ]),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('$memberPaid/$memberTotal payments',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400])),
                      Text('${(memberProgress * 100).round()}%',
                          style: GoogleFonts.outfit(fontSize: 12,
                              color: _primary, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(borderRadius: BorderRadius.circular(9999),
                      child: LinearProgressIndicator(
                        value: memberProgress, minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: const AlwaysStoppedAnimation(_primary))),
                    if (nextUnpaid.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.schedule_rounded, size: 13, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text('Next due: ${formatDate(nextUnpaid.first['dueDate'])}',
                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange)),
                        const SizedBox(width: 8),
                        Text(formatPeso(nextUnpaid.first['amount']),
                            style: GoogleFonts.outfit(fontSize: 12,
                                color: Colors.orange, fontWeight: FontWeight.w600)),
                      ]),
                    ],
                  ]),
                );
              }),
            ],

            // Pending applications
            if (pendingEnrollments.isNotEmpty) ...[
              _sectionLabel('Pending Applications'),
              const SizedBox(height: 10),
              ...pendingEnrollments.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.withOpacity(0.2))),
                child: Row(children: [
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.hourglass_empty_rounded,
                        color: Colors.orange, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m['paluwaganPackage']?['name'] ?? '',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    Text('Waiting for admin approval',
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange)),
                  ])),
                ])),
              ),
            ],

            if (_members.isEmpty && _orders.isEmpty)
              Container(padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: _card,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Container(padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _primary.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.storefront_rounded,
                        size: 36, color: _primary)),
                  const SizedBox(height: 12),
                  Text('Welcome to Gia Foodies!', style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Browse the Food Menu or apply for a Paluwagan package to get started.',
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[500]),
                      textAlign: TextAlign.center),
                ])),
          ]),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label, style: GoogleFonts.outfit(
      fontSize: 12, fontWeight: FontWeight.w600,
      color: Colors.grey[500], letterSpacing: 0.5));
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF162018),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.15))),
    child: Row(children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 17)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 15,
            fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.outfit(fontSize: 10,
            color: Colors.grey[500], fontWeight: FontWeight.w500)),
      ])),
    ]),
  );
}
