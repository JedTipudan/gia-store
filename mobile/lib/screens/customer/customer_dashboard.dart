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

class _CustomerDashboardState extends State<CustomerDashboard> {
  List _members = [];
  List _payments = [];
  List _orders = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

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
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final activeEnrollments = _members.where((m) => m['status'] == 'ACTIVE').toList();
    final pendingEnrollments = _members.where((m) => m['status'] == 'PENDING').toList();

    // Paluwagan payment stats
    final totalPayments = _payments.length;
    final paidPayments = _payments.where((p) => p['paid'] == true).length;
    final submittedPayments = _payments.where((p) => p['approvalStatus'] == 'SUBMITTED').length;
    final unpaidPayments = _payments.where((p) =>
        p['paid'] == false && p['approvalStatus'] == 'PENDING').length;
    final totalPaid = _payments.where((p) => p['paid'] == true)
        .fold(0.0, (sum, p) => sum + ((p['amount'] ?? 0) as num).toDouble());
    final progress = totalPayments > 0 ? paidPayments / totalPayments : 0.0;

    // Food order stats
    final pendingOrders = _orders.where((o) => o['status'] == 'PENDING').length;
    final paidOrders = _orders.where((o) => o['status'] == 'PAID').length;
    final confirmedOrders = _orders.where((o) => o['status'] == 'CONFIRMED').length;
    final totalOrderSpend = _orders.where((o) => o['status'] == 'CONFIRMED')
        .fold(0.0, (sum, o) => sum + ((o['totalPrice'] ?? 0) as num).toDouble());

    // Total pending actions
    final totalPending = pendingOrders + paidOrders + submittedPayments;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Welcome card
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0A2E14), Color(0xFF16a34a)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Welcome back,', style: GoogleFonts.outfit(
                    fontSize: 13, color: Colors.white.withOpacity(0.8))),
                Text(widget.username, style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(activeEnrollments.isEmpty
                    ? 'No active paluwagan yet'
                    : '${activeEnrollments.length} active enrollment${activeEnrollments.length > 1 ? 's' : ''}',
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: Colors.white.withOpacity(0.7))),
              ])),
              Container(width: 56, height: 56,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14)),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/logo.jpg', fit: BoxFit.cover)),
            ]),
          ),
          const SizedBox(height: 16),

          // Pending alert
          if (totalPending > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.notifications_active_rounded,
                    color: Colors.orange, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$totalPending pending action${totalPending > 1 ? 's' : ''}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                          color: Colors.orange)),
                  Text([
                    if (pendingOrders > 0) '$pendingOrders order${pendingOrders > 1 ? 's' : ''} waiting',
                    if (paidOrders > 0) '$paidOrders payment${paidOrders > 1 ? 's' : ''} submitted',
                    if (submittedPayments > 0) '$submittedPayments paluwagan payment${submittedPayments > 1 ? 's' : ''} submitted',
                  ].join(' • '),
                      style: GoogleFonts.outfit(fontSize: 12,
                          color: Colors.orange.withOpacity(0.8))),
                ])),
              ]),
            ),

          // Paluwagan stats
          _sectionLabel('Paluwagan Payments'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _statCard('Total Paid',
                formatPeso(totalPaid), Icons.payments_rounded,
                const Color(0xFF4ade80))),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Progress',
                '$paidPayments/$totalPayments', Icons.receipt_long_rounded,
                Colors.blue[300]!)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _statCard('Submitted',
                '$submittedPayments', Icons.hourglass_empty_rounded,
                Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Unpaid',
                '$unpaidPayments', Icons.warning_amber_rounded,
                Colors.red[300]!)),
          ]),

          // Payment progress bar
          if (totalPayments > 0) ...[
            const SizedBox(height: 14),
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF1A2E1E),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('$paidPayments of $totalPayments paid',
                      style: GoogleFonts.outfit(color: Colors.white,
                          fontWeight: FontWeight.w500, fontSize: 13)),
                  Text('${(progress * 100).round()}%',
                      style: GoogleFonts.outfit(color: const Color(0xFF4ade80),
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(
                    value: progress, minHeight: 8,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF16a34a)))),
              ])),
          ],
          const SizedBox(height: 16),

          // Food order stats
          _sectionLabel('Food Orders'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _statCard('Confirmed',
                '$confirmedOrders', Icons.check_circle_rounded,
                const Color(0xFF4ade80))),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Pending',
                '${pendingOrders + paidOrders}',
                Icons.pending_rounded, Colors.orange)),
          ]),
          if (totalOrderSpend > 0) ...[
            const SizedBox(height: 10),
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF1A2E1E),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.fastfood_rounded,
                    color: Color(0xFF4ade80), size: 20),
                const SizedBox(width: 10),
                Text('Total food spend: ', style: GoogleFonts.outfit(
                    color: Colors.grey[400], fontSize: 13)),
                Text(formatPeso(totalOrderSpend), style: GoogleFonts.outfit(
                    color: const Color(0xFF4ade80), fontWeight: FontWeight.bold,
                    fontSize: 15)),
              ])),
          ],
          const SizedBox(height: 16),

          // Active enrollments
          if (activeEnrollments.isNotEmpty) ...[
            _sectionLabel('Active Enrollments'),
            const SizedBox(height: 8),
            ...activeEnrollments.map((m) {
              final memberPayments = _payments
                  .where((p) => p['member']?['id'] == m['id']).toList();
              final memberPaid = memberPayments.where((p) => p['paid'] == true).length;
              final memberTotal = memberPayments.length;
              final nextUnpaid = memberPayments.where((p) =>
                  p['paid'] == false && p['approvalStatus'] == 'PENDING').toList();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF1A2E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF16a34a).withOpacity(0.3))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(m['paluwaganPackage']?['name'] ?? '',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                            color: Colors.white, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFF16a34a).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(9999)),
                      child: Text('ACTIVE', style: GoogleFonts.outfit(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: const Color(0xFF4ade80)))),
                  ]),
                  const SizedBox(height: 6),
                  Text('${formatPeso(m['paluwaganPackage']?['weeklyAmount'])}/week',
                      style: GoogleFonts.outfit(color: const Color(0xFF4ade80),
                          fontWeight: FontWeight.w600)),
                  Text('Started: ${formatDate(m['startDate'])}',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('$memberPaid/$memberTotal payments done',
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400])),
                    if (nextUnpaid.isNotEmpty)
                      Text('Next due: ${formatDate(nextUnpaid.first['dueDate'])}',
                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.orange)),
                  ]),
                ]),
              );
            }),
          ],

          // Pending applications
          if (pendingEnrollments.isNotEmpty) ...[
            const SizedBox(height: 8),
            _sectionLabel('Pending Applications'),
            const SizedBox(height: 8),
            ...pendingEnrollments.map((m) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF1A2E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.hourglass_empty_rounded,
                    color: Colors.orange, size: 20),
                const SizedBox(width: 10),
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
            Container(padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF1A2E1E),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                const Icon(Icons.storefront_rounded, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                Text('Nothing here yet', style: GoogleFonts.outfit(
                    color: Colors.grey[400])),
                const SizedBox(height: 4),
                Text('Browse Food Menu or Packages to get started',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center),
              ])),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label, style: GoogleFonts.outfit(
      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[400]));

  Widget _statCard(String label, String value, IconData icon, Color color) =>
      Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF1A2E1E),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: GoogleFonts.outfit(fontSize: 16,
                fontWeight: FontWeight.bold, color: color)),
            Text(label, style: GoogleFonts.outfit(fontSize: 10,
                color: Colors.grey[500], fontWeight: FontWeight.w500)),
          ])),
        ]));
}
