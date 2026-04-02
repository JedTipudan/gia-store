import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/dialogs.dart';
import 'payments_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});
  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List _pending = [], _active = [];
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
    final res = await ApiService.get('/paluwagan/members');
    if (res.statusCode == 200) {
      final all = jsonDecode(res.body) as List;
      setState(() {
        _pending = all.where((m) => m['status'] == 'PENDING').toList();
        _active = all.where((m) => m['status'] != 'PENDING').toList();
        _loading = false;
      });
    }
  }

  Future<void> _approve(Map m) async {
    final res = await ApiService.patch2('/paluwagan/members/${m['id']}/approve', {});
    if (!mounted) return;
    if (res.statusCode == 200) { showSnack(context, '${m['fullName']} approved ✓'); _load(); }
    else {
      final body = jsonDecode(res.body);
      showSnack(context, body['message'] ?? 'Failed to approve', error: true);
    }
  }

  Future<void> _reject(Map m) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(context: context,
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
    if (!ok) return;
    await ApiService.patch2('/paluwagan/members/${m['id']}/reject', {'note': noteCtrl.text});
    if (mounted) { showSnack(context, 'Application rejected'); _load(); }
  }

  Future<void> _delete(Map m) async {
    final ok = await confirmDelete(context, m['fullName']);
    if (!ok || !mounted) return;
    await ApiService.delete('/paluwagan/members/${m['id']}');
    if (mounted) { showSnack(context, 'Member removed'); _load(); }
  }

  void _openEdit(Map m) async {
    final result = await showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MemberEditForm(member: m),
    );
    if (result == true && mounted) { showSnack(context, 'Member updated!'); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: null,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tab,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          indicatorColor: const Color(0xFF16a34a),
          labelColor: const Color(0xFF16a34a),
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Pending (${_pending.length})'),
            Tab(text: 'Enrolled (${_active.length})'),
          ],
        ),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tab, children: [
              _pendingList(),
              _activeList(),
            ]),
    );
  }

  Widget _pendingList() {
    if (_pending.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
      const SizedBox(height: 12),
      Text('No pending applications', style: GoogleFonts.outfit(color: Colors.grey)),
    ]));
    return RefreshIndicator(onRefresh: _load,
      child: ListView.builder(padding: const EdgeInsets.all(16),
        itemCount: _pending.length,
        itemBuilder: (_, i) {
          final m = _pending[i];
          return Card(margin: const EdgeInsets.only(bottom: 10),
            child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(backgroundColor: const Color(0xFFFEF3C7),
                  child: Text((m['fullName'] ?? 'M')[0].toUpperCase(),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.orange))),
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
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.inventory_2_outlined, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(m['paluwaganPackage']?['name'] ?? '',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF16a34a), fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Applied: ${formatDate(m['appliedAt'])}',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _reject(m),
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  label: Text('Reject', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => _approve(m),
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

  Widget _activeList() {
    if (_active.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.people_outline, size: 64, color: Colors.grey),
      const SizedBox(height: 12),
      Text('No enrolled members yet', style: GoogleFonts.outfit(color: Colors.grey)),
    ]));
    return RefreshIndicator(onRefresh: _load,
      child: ListView.builder(padding: const EdgeInsets.all(16),
        itemCount: _active.length,
        itemBuilder: (_, i) {
          final m = _active[i];
          final status = m['status'] ?? 'ACTIVE';
          final statusColors = {'ACTIVE': const Color(0xFF16a34a), 'COMPLETED': const Color(0xFF2563eb), 'DROPPED': Colors.red, 'REJECTED': Colors.red};
          final statusBgs = {'ACTIVE': const Color(0xFFDCFCE7), 'COMPLETED': const Color(0xFFDBEAFE), 'DROPPED': const Color(0xFFFEE2E2), 'REJECTED': const Color(0xFFFEE2E2)};
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
                  decoration: BoxDecoration(color: statusBgs[status] ?? Colors.grey[100], borderRadius: BorderRadius.circular(9999)),
                  child: Text(status, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600,
                      color: statusColors[status] ?? Colors.grey))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.inventory_2_outlined, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(m['paluwaganPackage']?['name'] ?? '',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF16a34a), fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Since: ${formatDate(m['startDate'])}',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              ]),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                _btn('Payments', Icons.receipt_long, const Color(0xFFF0FDF4), const Color(0xFF16a34a),
                    () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => PaymentsScreen(memberId: m['id'])))),
                const SizedBox(width: 8),
                _btn('Edit', Icons.edit, const Color(0xFFDBEAFE), const Color(0xFF2563eb),
                    () => _openEdit(Map<String, dynamic>.from(m))),
                const SizedBox(width: 8),
                _btn('', Icons.delete, const Color(0xFFFEE2E2), Colors.red,
                    () => _delete(m), iconOnly: true),
              ]),
            ])));
        }));
  }

  Widget _btn(String label, IconData icon, Color bg, Color color, VoidCallback onTap, {bool iconOnly = false}) =>
      GestureDetector(onTap: onTap,
        child: Container(padding: EdgeInsets.symmetric(horizontal: iconOnly ? 8 : 10, vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: iconOnly ? Icon(icon, size: 14, color: color)
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 13, color: color), const SizedBox(width: 4),
                  Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                ])));
}

class _MemberEditForm extends StatefulWidget {
  final Map member;
  const _MemberEditForm({required this.member});
  @override
  State<_MemberEditForm> createState() => _MemberEditFormState();
}

class _MemberEditFormState extends State<_MemberEditForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String _status = 'ACTIVE';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _name.text = widget.member['fullName'] ?? '';
    _phone.text = widget.member['phone'] ?? '';
    _address.text = widget.member['address'] ?? '';
    _status = widget.member['status'] ?? 'ACTIVE';
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    await ApiService.put('/paluwagan/members/${widget.member['id']}',
        {'fullName': _name.text, 'phone': _phone.text, 'address': _address.text, 'status': _status});
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Edit Member', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 12),
        _f(_name, 'Full Name'), _f(_phone, 'Phone'), _f(_address, 'Address'),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: InputDecoration(labelText: 'Status', labelStyle: GoogleFonts.outfit(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          items: ['ACTIVE', 'COMPLETED', 'DROPPED'].map((s) =>
              DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.outfit()))).toList(),
          onChanged: (v) => setState(() => _status = v!),
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 46,
          child: ElevatedButton(onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text('Update', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)))),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _f(TextEditingController c, String l) =>
      Padding(padding: const EdgeInsets.only(bottom: 10),
        child: TextField(controller: c,
            decoration: InputDecoration(labelText: l, labelStyle: GoogleFonts.outfit(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            style: GoogleFonts.outfit()));
}
