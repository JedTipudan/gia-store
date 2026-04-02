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

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List _pendingProofs = [];
  List _paidPayments = [];
  List _memberPayments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: widget.memberId != null ? 1 : 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (widget.memberId != null) {
      final res = await ApiService.get('/paluwagan/payments/member/${widget.memberId}');
      if (res.statusCode == 200) setState(() { _memberPayments = jsonDecode(res.body); _loading = false; });
    } else {
      final pendingRes = await ApiService.get('/paluwagan/payments/pending-approvals');
      final paidRes = await ApiService.get('/paluwagan/payments/paid');
      setState(() {
        _pendingProofs = pendingRes.statusCode == 200 ? jsonDecode(pendingRes.body) : [];
        _paidPayments = paidRes.statusCode == 200 ? jsonDecode(paidRes.body) : [];
        _loading = false;
      });
    }
  }

  Future<void> _approvePayment(Map p) async {
    final res = await ApiService.patch2('/paluwagan/payments/${p['id']}/approve', {});
    if (!mounted) return;
    if (res.statusCode == 200) { showSnack(context, 'Payment approved ✓'); _load(); }
    else showSnack(context, 'Failed to approve', error: true);
  }

  Future<void> _rejectPayment(Map p) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Payment', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Reject payment from ${p['member']?['fullName']}?', style: GoogleFonts.outfit()),
          const SizedBox(height: 12),
          TextField(controller: noteCtrl,
              decoration: InputDecoration(labelText: 'Reason (optional)', labelStyle: GoogleFonts.outfit(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              style: GoogleFonts.outfit()),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('Reject', style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
        ],
      )) ?? false;
    if (!ok) return;
    await ApiService.patch2('/paluwagan/payments/${p['id']}/reject', {'note': noteCtrl.text});
    if (mounted) { showSnack(context, 'Payment rejected'); _load(); }
  }

  Future<void> _markPaid(Map p) async {
    await ApiService.patch('/paluwagan/payments/${p['id']}/pay');
    if (mounted) { showSnack(context, 'Marked as paid ✓'); _load(); }
  }

  Future<void> _markUnpaid(Map p) async {
    await ApiService.patch('/paluwagan/payments/${p['id']}/unpay');
    if (mounted) { showSnack(context, 'Marked as unpaid'); _load(); }
  }

  void _downloadReceipt(Map p) async {
    final token = await ApiService.getToken();
    final url = 'https://gia-store-production.up.railway.app/api/receipts/${p['id']}/pdf?token=$token';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isSubScreen = widget.memberId != null;
    return Scaffold(
      appBar: isSubScreen ? AppBar(
        title: Text('Member Payments', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ) : AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tab,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          indicatorColor: const Color(0xFF16a34a),
          labelColor: const Color(0xFF16a34a),
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Pending Review (${_pendingProofs.length})'),
            Tab(text: 'Paid History (${_paidPayments.length})'),
          ],
        ),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : isSubScreen
              ? _memberPaymentsList()
              : TabBarView(controller: _tab, children: [
                  _pendingProofsList(),
                  _paidHistoryList(),
                ]),
    );
  }

  Widget _pendingProofsList() {
    if (_pendingProofs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
      const SizedBox(height: 12),
      Text('No pending payment proofs', style: GoogleFonts.outfit(color: Colors.grey)),
    ]));
    return RefreshIndicator(onRefresh: _load,
      child: ListView.builder(padding: const EdgeInsets.all(16),
        itemCount: _pendingProofs.length,
        itemBuilder: (_, i) => _proofCard(_pendingProofs[i])));
  }

  Widget _proofCard(Map p) {
    final proofUrl = (p['proofImageUrl'] ?? '').toString();
    final fullProofUrl = proofUrl.startsWith('/api')
        ? 'https://gia-store-production.up.railway.app$proofUrl' : proofUrl;
    return Card(margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(p['member']?['fullName'] ?? '',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(9999)),
            child: Text('SUBMITTED', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.orange))),
        ]),
        const SizedBox(height: 4),
        Text('${p['periodLabel'] ?? 'Week ${p['periodNumber']}'} • ${formatPeso(p['amount'])}',
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF16a34a), fontWeight: FontWeight.w600)),
        Text('Package: ${p['member']?['paluwaganPackage']?['name'] ?? ''}',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
        if ((p['paymentMethod'] ?? '').toString().isNotEmpty)
          Text('Method: ${p['paymentMethod']}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
        if ((p['referenceNumber'] ?? '').toString().isNotEmpty)
          Text('Ref: ${p['referenceNumber']}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
        Text('Submitted: ${formatDate(p['submittedAt'])}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
        if (proofUrl.isNotEmpty) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => showDialog(context: context, builder: (_) => Dialog(
                child: InteractiveViewer(child: Image.network(fullProofUrl)))),
            child: ClipRRect(borderRadius: BorderRadius.circular(10),
              child: Image.network(fullProofUrl, height: 180, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 80, color: Colors.grey[100],
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))))),
          ),
          Text('Tap to view full size', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => _rejectPayment(p),
            icon: const Icon(Icons.close, size: 16, color: Colors.red),
            label: Text('Reject', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          )),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton.icon(
            onPressed: () => _approvePayment(p),
            icon: const Icon(Icons.check, size: 16),
            label: Text('Approve', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          )),
        ]),
      ])));
  }

  Widget _paidHistoryList() {
    if (_paidPayments.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
      const SizedBox(height: 12),
      Text('No paid payments yet', style: GoogleFonts.outfit(color: Colors.grey)),
    ]));
    return RefreshIndicator(onRefresh: _load,
      child: ListView.builder(padding: const EdgeInsets.all(16),
        itemCount: _paidPayments.length,
        itemBuilder: (_, i) {
          final p = _paidPayments[i];
          return Card(margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: const Color(0xFFDCFCE7),
                child: const Icon(Icons.check, color: Color(0xFF16a34a), size: 18)),
              title: Text(p['member']?['fullName'] ?? '',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p['periodLabel'] ?? 'Week ${p['periodNumber']}'} • ${p['member']?['paluwaganPackage']?['name'] ?? ''}',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                if ((p['paymentMethod'] ?? '').toString().isNotEmpty)
                  Text('via ${p['paymentMethod']}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                Text('Paid: ${formatDate(p['paidAt'])}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
              ]),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatPeso(p['amount']), style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, color: const Color(0xFF16a34a), fontSize: 14)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ReceiptScreen(payment: p))),
                  child: Text('View Receipt', style: GoogleFonts.outfit(fontSize: 10,
                      color: const Color(0xFF2563eb), decoration: TextDecoration.underline)),
                ),
              ]),
            ));
        }));
  }

  Widget _memberPaymentsList() {
    if (_memberPayments.isEmpty) return Center(child: Text('No payments', style: GoogleFonts.outfit(color: Colors.grey)));
    return RefreshIndicator(onRefresh: _load,
      child: ListView.builder(padding: const EdgeInsets.all(16),
        itemCount: _memberPayments.length,
        itemBuilder: (_, i) {
          final p = _memberPayments[i];
          final isPaid = p['paid'] == true;
          final status = p['approvalStatus'] ?? 'PENDING';
          return Card(margin: const EdgeInsets.only(bottom: 8),
            child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(p['periodLabel'] ?? 'Week ${p['periodNumber']}',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                _statusBadge(isPaid ? 'PAID' : status),
              ]),
              Text('Due: ${formatDate(p['dueDate'])}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              if ((p['paymentMethod'] ?? '').toString().isNotEmpty)
                Text('Method: ${p['paymentMethod']}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              if ((p['receiptNumber'] ?? '').toString().isNotEmpty)
                Text('Receipt: ${p['receiptNumber']}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(formatPeso(p['amount']), style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF16a34a))),
                Row(children: [
                  if (!isPaid && status != 'SUBMITTED')
                    _actionBtn('Mark Paid', Icons.check_circle, const Color(0xFF16a34a), () => _markPaid(p))
                  else if (isPaid) ...[
                    _actionBtn('Receipt', Icons.receipt, const Color(0xFF2563eb),
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptScreen(payment: p)))),
                    const SizedBox(width: 6),
                    _actionBtn('Unpay', Icons.cancel, Colors.orange, () => _markUnpaid(p)),
                  ],
                ]),
              ]),
            ])));
        }));
  }

  Widget _statusBadge(String status) {
    final colors = {'PAID': const Color(0xFF16a34a), 'SUBMITTED': Colors.orange, 'REJECTED': Colors.red, 'APPROVED': const Color(0xFF16a34a), 'PENDING': Colors.grey};
    final bgs = {'PAID': const Color(0xFFDCFCE7), 'SUBMITTED': const Color(0xFFFEF3C7), 'REJECTED': const Color(0xFFFEE2E2), 'APPROVED': const Color(0xFFDCFCE7), 'PENDING': Colors.grey[100]!};
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bgs[status] ?? Colors.grey[100], borderRadius: BorderRadius.circular(9999)),
      child: Text(status, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: colors[status] ?? Colors.grey)));
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: color), const SizedBox(width: 4),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ])));
}
