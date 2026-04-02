import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/dialogs.dart';
import 'receipt_screen.dart';

class PaymentsScreen extends StatefulWidget {
  final int? memberId;
  const PaymentsScreen({super.key, this.memberId});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List _payments = [];
  List _members = [];
  bool _loading = true;
  String _filter = 'ALL';
  int? _selectedMember;

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.memberId;
    _load();
    if (widget.memberId == null) _loadMembers();
  }

  Future<void> _loadMembers() async {
    final res = await ApiService.get('/paluwagan/members');
    if (res.statusCode == 200) setState(() => _members = jsonDecode(res.body));
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final path = _selectedMember != null
          ? '/paluwagan/payments/member/$_selectedMember'
          : '/paluwagan/payments';
      final res = await ApiService.get(path);
      if (res.statusCode == 200) setState(() { _payments = jsonDecode(res.body); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _markPaid(Map p) async {
    await ApiService.patch('/paluwagan/payments/${p['id']}/pay');
    if (mounted) showSnack(context, 'Payment marked as paid ✓');
    _load();
  }

  Future<void> _markUnpaid(Map p) async {
    await ApiService.patch('/paluwagan/payments/${p['id']}/unpay');
    if (mounted) showSnack(context, 'Payment marked as unpaid');
    _load();
  }

  Future<void> _delete(Map p) async {
    final ok = await confirmDelete(context, 'Week ${p['weekNumber']} payment');
    if (!ok || !mounted) return;
    final res = await ApiService.delete('/paluwagan/payments/${p['id']}');
    if (!mounted) return;
    if (res.statusCode == 200) { showSnack(context, 'Payment deleted'); _load(); }
    else showSnack(context, 'Cannot delete this payment', error: true);
  }

  void _viewReceipt(Map p) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptScreen(payment: p)));
  }

  void _downloadReceipt(Map p) async {
    final token = await ApiService.getToken();
    final url = 'https://gia-store-production.up.railway.app/api/receipts/${p['id']}/pdf?token=$token';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List get _filtered => _payments.where((p) {
    if (_filter == 'PAID') return p['paid'] == true;
    if (_filter == 'UNPAID') return p['paid'] == false;
    return true;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final isSubScreen = widget.memberId != null;
    final paidCount = _payments.where((p) => p['paid'] == true).length;
    final unpaidCount = _payments.where((p) => p['paid'] == false).length;

    return Scaffold(
      appBar: isSubScreen ? AppBar(
        title: Text('Payments', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ) : null,
      body: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.all(12),
          child: Column(children: [
            if (!isSubScreen && _members.isNotEmpty)
              DropdownButtonFormField<int>(
                value: _selectedMember,
                decoration: InputDecoration(labelText: 'Filter by Member', labelStyle: GoogleFonts.outfit(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: [
                  DropdownMenuItem(value: null, child: Text('All Members', style: GoogleFonts.outfit())),
                  ..._members.map((m) => DropdownMenuItem(value: m['id'] as int,
                      child: Text(m['fullName'], style: GoogleFonts.outfit()))),
                ],
                onChanged: (v) { setState(() => _selectedMember = v); _load(); },
              ),
            const SizedBox(height: 8),
            Row(children: [
              _chip('ALL', null),
              const SizedBox(width: 8),
              _chip('PAID', paidCount, color: const Color(0xFF16a34a)),
              const SizedBox(width: 8),
              _chip('UNPAID', unpaidCount, color: Colors.red),
            ]),
          ]),
        ),
        Expanded(
          child: _loading ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _filtered.isEmpty
                      ? Center(child: Text('No payments found', style: GoogleFonts.outfit(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final p = _filtered[i];
                            final isPaid = p['paid'] == true;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Expanded(child: Text(p['member']?['fullName'] ?? '',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(9999)),
                                      child: Text(isPaid ? 'Paid' : 'Unpaid',
                                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600,
                                              color: isPaid ? const Color(0xFF16a34a) : Colors.red)),
                                    ),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text('Week ${p['weekNumber']} • Due: ${formatDate(p['dueDate'])}',
                                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                                  if (p['receiptNumber'] != null)
                                    Text('Receipt: ${p['receiptNumber']}',
                                        style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[400])),
                                  const SizedBox(height: 10),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Text(formatPeso(p['amount']), style: GoogleFonts.outfit(
                                        fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF16a34a))),
                                    Wrap(spacing: 6, children: [
                                      if (!isPaid)
                                        _actionBtn('Pay', Icons.check_circle, const Color(0xFF16a34a), () => _markPaid(p))
                                      else ...[
                                        _actionBtn('Receipt', Icons.receipt, const Color(0xFF7c3aed), () => _viewReceipt(p)),
                                        _actionBtn('PDF', Icons.download, const Color(0xFF2563eb), () => _downloadReceipt(p)),
                                        _actionBtn('Unpay', Icons.cancel, Colors.orange, () => _markUnpaid(p)),
                                      ],
                                      _actionBtn('', Icons.delete, Colors.red, () => _delete(p), iconOnly: true),
                                    ]),
                                  ]),
                                ]),
                              ),
                            );
                          }),
                ),
        ),
      ]),
    );
  }

  Widget _chip(String label, int? count, {Color? color}) {
    final selected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? (color ?? const Color(0xFF16a34a)) : Colors.grey[100],
          borderRadius: BorderRadius.circular(9999)),
        child: Text(count != null ? '$label ($count)' : label,
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[700])),
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap, {bool iconOnly = false}) =>
      GestureDetector(onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: iconOnly ? 6 : 10, vertical: 6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: iconOnly ? Icon(icon, size: 14, color: color)
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 13, color: color), const SizedBox(width: 4),
                  Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                ]),
        ));
}
