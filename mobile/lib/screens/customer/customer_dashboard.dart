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
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (widget.userId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final mRes = await ApiService.get('/paluwagan/members/user/${widget.userId}');
      final pRes = await ApiService.get('/paluwagan/payments/user/${widget.userId}');
      setState(() {
        _members = mRes.statusCode == 200 ? jsonDecode(mRes.body) : [];
        _payments = pRes.statusCode == 200 ? jsonDecode(pRes.body) : [];
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final activeEnrollments = _members.where((m) => m['status'] == 'ACTIVE').toList();
    final pendingEnrollments = _members.where((m) => m['status'] == 'PENDING').toList();
    final totalPayments = _payments.length;
    final paidPayments = _payments.where((p) => p['paid'] == true).length;
    final pendingProofs = _payments.where((p) => p['approvalStatus'] == 'SUBMITTED').length;
    final unpaidPayments = _payments.where((p) => p['paid'] == false && p['approvalStatus'] != 'SUBMITTED').length;
    final totalPaid = _payments.where((p) => p['paid'] == true)
        .fold(0.0, (sum, p) => sum + (p['amount'] ?? 0));
    final progress = totalPayments > 0 ? paidPayments / totalPayments : 0.0;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Welcome
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF14532d), Color(0xFF166534)],
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
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withOpacity(0.7))),
              ])),
              Container(width: 56, height: 56,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14)),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/logo.jpg', fit: BoxFit.cover)),
            ]),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(children: [
            Expanded(child: _statCard('Total Paid', formatPeso(totalPaid),
                Icons.payments_rounded, const Color(0xFF4ade80))),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Payments', '$paidPayments/$totalPayments',
                Icons.receipt_long_rounded, Colors.blue[300]!)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _statCard('Pending Review', '$pendingProofs',
                Icons.hourglass_empty_rounded, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Unpaid', '$unpaidPayments',
                Icons.warning_amber_rounded, Colors.red[300]!)),
          ]),
          const SizedBox(height: 16),

          // Payment progress
          if (totalPayments > 0) ...[
            Text('Payment Progress', style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[400])),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1A2E1E),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('$paidPayments of $totalPayments paid',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500)),
                  Text('${(progress * 100).round()}%',
                      style: GoogleFonts.outfit(color: const Color(0xFF4ade80),
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(
                    value: progress, minHeight: 10,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF16a34a)))),
              ])),
            const SizedBox(height: 16),
          ],

          // Active enrollments
          if (activeEnrollments.isNotEmpty) ...[
            Text('Active Enrollments', style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[400])),
            const SizedBox(height: 8),
            ...activeEnrollments.map((m) {
              final memberPayments = _payments.where(
                  (p) => p['member']?['id'] == m['id']).toList();
              final memberPaid = memberPayments.where((p) => p['paid'] == true).length;
              final memberTotal = memberPayments.length;
              final nextUnpaid = memberPayments.where(
                  (p) => p['paid'] == false && p['approvalStatus'] != 'SUBMITTED').toList();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF1A2E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF16a34a).withOpacity(0.3))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(m['paluwaganPackage']?['name'] ?? '',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                            color: Colors.white, fontSize: 15)),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF16a34a).withOpacity(0.2),
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
            Text('Pending Applications', style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[400])),
            const SizedBox(height: 8),
            ...pendingEnrollments.map((m) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF1A2E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m['paluwaganPackage']?['name'] ?? '',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white)),
                  Text('Waiting for admin approval',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange)),
                ])),
              ]),
            )),
          ],

          if (_members.isEmpty)
            Container(padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2E1E),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                const Icon(Icons.groups_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                Text('No paluwagan enrollment yet',
                    style: GoogleFonts.outfit(color: Colors.grey[400])),
                const SizedBox(height: 4),
                Text('Go to Packages to apply',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
              ])),
        ]),
      ),
    );
  }

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
