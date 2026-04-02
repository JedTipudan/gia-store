import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/dialogs.dart';

class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});
  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List _pendingMembers = [];
  List _pendingPayments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final mRes = await ApiService.get('/paluwagan/members/pending');
    final pRes = await ApiService.get('/paluwagan/payments/pending-approvals');
    setState(() {
      _pendingMembers = mRes.statusCode == 200 ? jsonDecode(mRes.body) : [];
      _pendingPayments = pRes.statusCode == 200 ? jsonDecode(pRes.body) : [];
      _loading = false;
    });
  }

  Future<void> _approveMember(Map m) async {
    final res = await ApiService.patch2('/paluwagan/members/${m['id']}/approve', {});
    if (!mounted) return;
    if (res.statusCode == 200) { showSnack(context, '${m['fullName']} approved ✓'); _load(); }
    else showSnack(context, 'Failed to approve', error: true);
  }

  Future<void> _rejectMember(Map m) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Application', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Reject ${m['fullName']}\'s application?', style: GoogleFonts.outfit()),
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
    if (!confirmed) return;
    final res = await ApiService.patch2('/paluwagan/members/${m['id']}/reject', {'note': noteCtrl.text});
    if (!mounted) return;
    if (res.statusCode == 200) { showSnack(context, 'Application rejected'); _load(); }
  }

  Future<void> _approvePayment(Map p) async {
    final res = await ApiService.patch2('/paluwagan/payments/${p['id']}/approve', {});
    if (!mounted) return;
    if (res.statusCode == 200) { showSnack(context, 'Payment approved ✓'); _load(); }
    else showSnack(context, 'Failed to approve', error: true);
  }

  Future<void> _rejectPayment(Map p) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Payment', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Reject payment proof from ${p['member']?['fullName']}?', style: GoogleFonts.outfit()),
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
    if (!confirmed) return;
    final res = await ApiService.patch2('/paluwagan/payments/${p['id']}/reject', {'note': noteCtrl.text});
    if (!mounted) return;
    if (res.statusCode == 200) { showSnack(context, 'Payment rejected'); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Approvals', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          indicatorColor: const Color(0xFF16a34a),
          labelColor: const Color(0xFF16a34a),
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Members (${_pendingMembers.length})'),
            Tab(text: 'Payments (${_pendingPayments.length})'),
          ],
        ),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tab, children: [
              _membersList(),
              _paymentsList(),
            ]),
    );
  }

  Widget _membersList() {
    if (_pendingMembers.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
      const SizedBox(height: 12),
      Text('No pending member applications', style: GoogleFonts.outfit(color: Colors.grey)),
    ]));
    return RefreshIndicator(onRefresh: _load,
      child: ListView.builder(padding: const EdgeInsets.all(16),
        itemCount: _pendingMembers.length,
        itemBuilder: (_, i) {
          final m = _pendingMembers[i];
          return Card(margin: const EdgeInsets.only(bottom: 10),
            child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(backgroundColor: const Color(0xFFDCFCE7),
                  child: Text((m['fullName'] ?? 'M')[0].toUpperCase(),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF16a34a)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m['fullName'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  if ((m['phone'] ?? '').toString().isNotEmpty)
                    Text(m['phone'], style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(9999)),
                  child: Text('PENDING', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.orange))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(m['paluwaganPackage']?['name'] ?? '', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF16a34a), fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Applied: ${formatDate(m['appliedAt'])}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _rejectMember(m),
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  label: Text('Reject', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => _approveMember(m),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text('Approve', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                )),
              ]),
            ])));
        }));
  }

  Widget _paymentsList() {
    if (_pendingPayments.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
      const SizedBox(height: 12),
      Text('No pending payment approvals', style: GoogleFonts.outfit(color: Colors.grey)),
    ]));
    return RefreshIndicator(onRefresh: _load,
      child: ListView.builder(padding: const EdgeInsets.all(16),
        itemCount: _pendingPayments.length,
        itemBuilder: (_, i) {
          final p = _pendingPayments[i];
          final proofUrl = (p['proofImageUrl'] ?? '').toString();
          final fullProofUrl = proofUrl.startsWith('/api')
              ? 'https://gia-store-production.up.railway.app$proofUrl'
              : proofUrl;
          return Card(margin: const EdgeInsets.only(bottom: 10),
            child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(p['member']?['fullName'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(9999)),
                  child: Text('SUBMITTED', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.orange))),
              ]),
              Text('Week ${p['weekNumber']} • ${formatPeso(p['amount'])}',
                  style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF16a34a), fontWeight: FontWeight.w600)),
              if ((p['paymentMethod'] ?? '').toString().isNotEmpty)
                Text('Method: ${p['paymentMethod']}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              if ((p['referenceNumber'] ?? '').toString().isNotEmpty)
                Text('Ref: ${p['referenceNumber']}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              Text('Submitted: ${formatDate(p['submittedAt'])}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              if (proofUrl.isNotEmpty) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => showDialog(context: context, builder: (_) => Dialog(
                    child: Image.network(fullProofUrl, fit: BoxFit.contain))),
                  child: ClipRRect(borderRadius: BorderRadius.circular(10),
                    child: Image.network(fullProofUrl, height: 160, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(height: 80, color: Colors.grey[100],
                            child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))))),
                ),
                const SizedBox(height: 4),
                Text('Tap image to view full size', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
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
        }));
  }
}
