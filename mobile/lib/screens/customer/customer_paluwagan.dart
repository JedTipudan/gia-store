import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/dialogs.dart';
import '../payment_page.dart';

class CustomerPaluwagan extends StatefulWidget {
  final String userId;
  const CustomerPaluwagan({super.key, required this.userId});
  @override
  State<CustomerPaluwagan> createState() => _CustomerPaluwaganState();
}

class _CustomerPaluwaganState extends State<CustomerPaluwagan> {
  List _members = [];
  Map<int, List> _paymentsByMember = {};
  bool _loading = true;

  static const _primary = Color(0xFF22c55e);
  static const _card = Color(0xFF162018);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (widget.userId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final mRes = await ApiService.get('/paluwagan/members/user/${widget.userId}');
      if (mRes.statusCode == 200) {
        final members = jsonDecode(mRes.body) as List;
        final paymentsMap = <int, List>{};
        for (final m in members) {
          if (m['status'] == 'ACTIVE') {
            final pRes = await ApiService.get('/paluwagan/payments/member/${m['id']}');
            if (pRes.statusCode == 200) {
              paymentsMap[m['id'] as int] = jsonDecode(pRes.body);
            }
          }
        }
        setState(() {
          _members = members;
          _paymentsByMember = paymentsMap;
          _loading = false;
        });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(
        child: CircularProgressIndicator(color: _primary));

    if (_members.isEmpty) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.groups_outlined, size: 72, color: Colors.grey[700]),
        const SizedBox(height: 16),
        Text('No paluwagan enrollment yet',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[400])),
        const SizedBox(height: 8),
        Text('Go to Packages tab to apply',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600])),
      ]));

    return RefreshIndicator(
      onRefresh: _load,
      color: _primary,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        ..._members.map((m) => _enrollmentSection(m)),
      ]),
    );
  }

  Widget _enrollmentSection(Map m) {
    final status = m['status'] ?? 'PENDING';
    final pkg = m['paluwaganPackage'] ?? {};
    final payments = _paymentsByMember[m['id'] as int] ?? [];
    final paidCount = payments.where((p) => p['paid'] == true).length;
    final total = payments.length;
    final progress = total > 0 ? paidCount / total : 0.0;
    final nextUnpaid = payments.where((p) =>
        p['paid'] == false && p['approvalStatus'] == 'PENDING').toList();
    final submittedPayments = payments.where((p) =>
        p['approvalStatus'] == 'SUBMITTED').toList();
    final months = pkg['durationMonths'] ?? pkg['durationWeeks'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor(status).withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _statusColor(status).withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pkg['name'] ?? '', style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.payments_outlined, size: 13, color: _statusColor(status)),
                const SizedBox(width: 4),
                Text('${formatPeso(pkg['weeklyAmount'])}/month',
                    style: GoogleFonts.outfit(fontSize: 12,
                        color: _statusColor(status), fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Icon(Icons.calendar_month_rounded, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('$months months',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400])),
              ]),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9999)),
              child: Text(status, style: GoogleFonts.outfit(
                  fontSize: 11, fontWeight: FontWeight.bold,
                  color: _statusColor(status)))),
          ]),
        ),

        Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [

          if (status == 'PENDING')
            _infoBox(Icons.hourglass_empty_rounded, Colors.orange,
                'Your application is being reviewed by the admin.'),

          if (status == 'REJECTED')
            _infoBox(Icons.cancel_outlined, Colors.red,
                'Application rejected${(m['adminNote'] ?? '').toString().isNotEmpty ? ': ${m['adminNote']}' : ''}'),

          if (status == 'ACTIVE') ...[
            // Progress tracker
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Payment Progress', style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[400])),
              Text('$paidCount / $total', style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.bold, color: _primary)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(9999),
              child: LinearProgressIndicator(
                value: progress, minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation(_primary))),
            const SizedBox(height: 4),
            Text('${(progress * 100).round()}% complete',
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500])),
            const SizedBox(height: 16),

            // Submitted waiting
            if (submittedPayments.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.2))),
                child: Row(children: [
                  const Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text('${submittedPayments.length} payment${submittedPayments.length > 1 ? 's' : ''} waiting for admin approval',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange)),
                ])),

            // Next payment — PAY NOW
            if (nextUnpaid.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _primary.withOpacity(0.25))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(nextUnpaid.first['periodLabel'] ??
                          'Month ${nextUnpaid.first['periodNumber']}',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                              color: Colors.white, fontSize: 14)),
                      Text('Due: ${formatDate(nextUnpaid.first['dueDate'])}',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400])),
                    ]),
                    Text(formatPeso(nextUnpaid.first['amount']),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                            color: _primary, fontSize: 22)),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openPayment(nextUnpaid.first),
                      icon: const Icon(Icons.payment_rounded, size: 20),
                      label: Text('Pay Now', style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    )),
                ])),
              const SizedBox(height: 16),
            ],

            // All payments
            Text('Payment Schedule', style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[400])),
            const SizedBox(height: 8),
            ...payments.map((p) => _paymentRow(p)),
          ],
        ])),
      ]),
    );
  }

  Widget _infoBox(IconData icon, Color color, String msg) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: GoogleFonts.outfit(fontSize: 12, color: color))),
    ]));

  Widget _paymentRow(Map p) {
    final isPaid = p['paid'] == true;
    final status = p['approvalStatus'] ?? 'PENDING';
    Color color;
    IconData icon;
    String label;

    if (isPaid) {
      color = _primary; icon = Icons.check_circle_rounded; label = 'Paid';
    } else if (status == 'SUBMITTED') {
      color = Colors.orange; icon = Icons.hourglass_empty_rounded; label = 'Pending';
    } else if (status == 'REJECTED') {
      color = Colors.red; icon = Icons.cancel_rounded; label = 'Rejected';
    } else {
      color = Colors.grey[600]!; icon = Icons.radio_button_unchecked; label = 'Unpaid';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15))),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p['periodLabel'] ?? 'Month ${p['periodNumber']}',
              style: GoogleFonts.outfit(fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isPaid ? Colors.white : Colors.grey[400])),
          Text('Due: ${formatDate(p['dueDate'])}',
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[600])),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(formatPeso(p['amount']), style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, color: color, fontSize: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9999)),
            child: Text(label, style: GoogleFonts.outfit(
                fontSize: 9, fontWeight: FontWeight.w600, color: color))),
        ]),
      ]),
    );
  }

  void _openPayment(Map payment) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PaymentPage(
        title: payment['periodLabel'] ?? 'Month ${payment['periodNumber']}',
        subtitle: 'Paluwagan Monthly Payment',
        amount: formatPeso(payment['amount']),
        paymentId: payment['id'].toString(),
        paymentType: 'paluwagan',
        onSuccess: () {
          _load();
          if (mounted) showSnack(context, '✓ Payment submitted! Waiting for admin approval.');
        },
      ),
    ));
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'ACTIVE': return _primary;
      case 'PENDING': return Colors.orange;
      case 'REJECTED': return Colors.red;
      case 'COMPLETED': return Colors.blue[300]!;
      default: return Colors.grey;
    }
  }
}
