import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/dialogs.dart';
import 'customer_payments.dart';

class CustomerPaluwagan extends StatefulWidget {
  final String userId;
  const CustomerPaluwagan({super.key, required this.userId});
  @override
  State<CustomerPaluwagan> createState() => _CustomerPaluwaganState();
}

class _CustomerPaluwaganState extends State<CustomerPaluwagan> {
  List _members = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (widget.userId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/paluwagan/members/user/${widget.userId}');
      if (res.statusCode == 200) setState(() { _members = jsonDecode(res.body); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'ACTIVE': return const Color(0xFF4ade80);
      case 'PENDING': return Colors.orange;
      case 'REJECTED': return Colors.red;
      case 'COMPLETED': return Colors.blue[300]!;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_members.isEmpty) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.groups_outlined, size: 72, color: Colors.grey[700]),
        const SizedBox(height: 16),
        Text('No paluwagan enrollment yet', style: GoogleFonts.outfit(
            fontSize: 16, color: Colors.grey[400])),
        const SizedBox(height: 8),
        Text('Go to Packages tab to apply', style: GoogleFonts.outfit(
            fontSize: 13, color: Colors.grey[600])),
      ],
    ));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('My Paluwagan', style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text('Your enrollment history and payment schedules',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[400])),
        const SizedBox(height: 16),
        ..._members.map((m) => _enrollmentCard(m)),
      ]),
    );
  }

  Widget _enrollmentCard(Map m) {
    final status = m['status'] ?? 'PENDING';
    final color = _statusColor(status);
    final pkg = m['paluwaganPackage'] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: const Color(0xFF1A2E1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14))),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pkg['name'] ?? '', style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.payments_outlined, size: 13, color: color),
                const SizedBox(width: 4),
                Text('${formatPeso(pkg['weeklyAmount'])}/week',
                    style: GoogleFonts.outfit(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('${pkg['durationWeeks']} weeks',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400])),
              ]),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9999)),
              child: Text(status, style: GoogleFonts.outfit(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color))),
          ]),
        ),
        // Details
        Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (status == 'PENDING')
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Your application is being reviewed by the admin.',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange))),
              ]))
          else if (status == 'REJECTED')
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Text('Application rejected', style: GoogleFonts.outfit(
                      fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                ]),
                if ((m['adminNote'] ?? '').toString().isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 4),
                    child: Text('Reason: ${m['adminNote']}',
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.red.withOpacity(0.8)))),
              ]))
          else if (status == 'ACTIVE') ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Started', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500])),
              Text(formatDate(m['startDate']), style: GoogleFonts.outfit(
                  fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CustomerPayments(userId: widget.userId,
                        memberId: m['id']))),
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: Text('View Payment Schedule',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16a34a),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              )),
          ],
        ])),
      ]),
    );
  }
}
