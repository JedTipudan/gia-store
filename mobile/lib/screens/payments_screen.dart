import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

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

  Future<void> _markPaid(int id) async {
    await ApiService.patch('/paluwagan/payments/$id/pay');
    _load();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment marked as paid ✓'),
            backgroundColor: Color(0xFF16a34a)));
  }

  Future<void> _markUnpaid(int id) async {
    await ApiService.patch('/paluwagan/payments/$id/unpay');
    _load();
  }

  void _downloadReceipt(Map payment) async {
    final url = 'https://gia-store-production.up.railway.app/api/receipts/${payment['id']}/pdf';
    final token = await ApiService.getToken();
    final uri = Uri.parse('$url?token=$token');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(children: [
              if (!isSubScreen && _members.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: _selectedMember,
                  decoration: InputDecoration(
                    labelText: 'Filter by Member',
                    labelStyle: GoogleFonts.outfit(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text('All Members', style: GoogleFonts.outfit())),
                    ..._members.map((m) => DropdownMenuItem(
                        value: m['id'] as int,
                        child: Text(m['fullName'], style: GoogleFonts.outfit()))),
                  ],
                  onChanged: (v) { setState(() => _selectedMember = v); _load(); },
                ),
              const SizedBox(height: 8),
              Row(children: [
                _FilterChip('ALL', _filter, () => setState(() => _filter = 'ALL')),
                const SizedBox(width: 8),
                _FilterChip('PAID', _filter, () => setState(() => _filter = 'PAID'),
                    count: paidCount, color: const Color(0xFF16a34a)),
                const SizedBox(width: 8),
                _FilterChip('UNPAID', _filter, () => setState(() => _filter = 'UNPAID'),
                    count: unpaidCount, color: Colors.red),
              ]),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                          borderRadius: BorderRadius.circular(9999),
                                        ),
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
                                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Text(formatPeso(p['amount']),
                                          style: GoogleFonts.outfit(fontSize: 18,
                                              fontWeight: FontWeight.bold, color: const Color(0xFF16a34a))),
                                      Row(children: [
                                        if (!isPaid)
                                          ElevatedButton.icon(
                                            onPressed: () => _markPaid(p['id']),
                                            icon: const Icon(Icons.check, size: 16),
                                            label: Text('Pay', style: GoogleFonts.outfit(fontSize: 13)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF16a34a),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          )
                                        else ...[
                                          OutlinedButton.icon(
                                            onPressed: () => _markUnpaid(p['id']),
                                            icon: const Icon(Icons.close, size: 16),
                                            label: Text('Unpay', style: GoogleFonts.outfit(fontSize: 13)),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: () => _downloadReceipt(p),
                                            icon: const Icon(Icons.download, size: 16),
                                            label: Text('PDF', style: GoogleFonts.outfit(fontSize: 13)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF2563eb),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      ]),
                                    ]),
                                  ]),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label, current;
  final VoidCallback onTap;
  final int? count;
  final Color? color;
  const _FilterChip(this.label, this.current, this.onTap, {this.count, this.color});

  @override
  Widget build(BuildContext context) {
    final selected = label == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? (color ?? const Color(0xFF16a34a)) : Colors.grey[100],
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(count != null ? '$label ($count)' : label,
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[700])),
      ),
    );
  }
}
