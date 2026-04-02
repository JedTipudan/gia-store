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

class _MembersScreenState extends State<MembersScreen> {
  List _members = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/paluwagan/members');
      if (res.statusCode == 200) setState(() { _members = jsonDecode(res.body); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  void _openForm([Map? member]) async {
    final result = await showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MemberForm(member: member),
    );
    if (result == true && mounted) {
      showSnack(context, member != null ? 'Member updated!' : 'Member added!');
      _load();
    }
  }

  Future<void> _delete(Map member) async {
    final ok = await confirmDelete(context, member['fullName']);
    if (!ok || !mounted) return;
    final res = await ApiService.delete('/paluwagan/members/${member['id']}');
    if (!mounted) return;
    if (res.statusCode == 200) { showSnack(context, 'Member removed'); _load(); }
    else showSnack(context, 'Failed to remove member', error: true);
  }

  Color _statusColor(String s) => s == 'ACTIVE' ? const Color(0xFF16a34a) : s == 'COMPLETED' ? const Color(0xFF2563eb) : Colors.red;
  Color _statusBg(String s) => s == 'ACTIVE' ? const Color(0xFFDCFCE7) : s == 'COMPLETED' ? const Color(0xFFDBEAFE) : const Color(0xFFFEE2E2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _members.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No members yet', style: GoogleFonts.outfit(color: Colors.grey)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _members.length,
                      itemBuilder: (_, i) {
                        final m = _members[i];
                        final status = m['status'] ?? 'ACTIVE';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                CircleAvatar(backgroundColor: const Color(0xFFDCFCE7), radius: 22,
                                  child: Text((m['fullName'] ?? 'M')[0].toUpperCase(),
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                                          color: const Color(0xFF16a34a), fontSize: 16))),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(m['fullName'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                  if ((m['phone'] ?? '').toString().isNotEmpty)
                                    Text(m['phone'], style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                                ])),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: _statusBg(status), borderRadius: BorderRadius.circular(9999)),
                                  child: Text(status, style: GoogleFonts.outfit(fontSize: 10,
                                      fontWeight: FontWeight.w600, color: _statusColor(status))),
                                ),
                              ]),
                              const SizedBox(height: 10),
                              Row(children: [
                                const Icon(Icons.inventory_2_outlined, size: 13, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(m['paluwaganPackage']?['name'] ?? '',
                                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF16a34a), fontWeight: FontWeight.w500)),
                                const SizedBox(width: 12),
                                const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(formatDate(m['startDate']), style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                              ]),
                              const SizedBox(height: 10),
                              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                _btn('Payments', Icons.payment, const Color(0xFFF0FDF4), const Color(0xFF16a34a),
                                    () => Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => PaymentsScreen(memberId: m['id'])))),
                                const SizedBox(width: 8),
                                _btn('Edit', Icons.edit, const Color(0xFFDBEAFE), const Color(0xFF2563eb),
                                    () => _openForm(Map<String, dynamic>.from(m))),
                                const SizedBox(width: 8),
                                _btn('Delete', Icons.delete, const Color(0xFFFEE2E2), Colors.red,
                                    () => _delete(m)),
                              ]),
                            ]),
                          ),
                        );
                      }),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF16a34a),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _btn(String label, IconData icon, Color bg, Color color, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: color), const SizedBox(width: 4),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ])));
}

class _MemberForm extends StatefulWidget {
  final Map? member;
  const _MemberForm({this.member});
  @override
  State<_MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<_MemberForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String _status = 'ACTIVE';
  String? _packageId;
  String _startDate = '';
  List _packages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPackages();
    if (widget.member != null) {
      _name.text = widget.member!['fullName'] ?? '';
      _phone.text = widget.member!['phone'] ?? '';
      _address.text = widget.member!['address'] ?? '';
      _status = widget.member!['status'] ?? 'ACTIVE';
    }
  }

  Future<void> _loadPackages() async {
    final res = await ApiService.get('/paluwagan/packages');
    if (res.statusCode == 200) setState(() => _packages = jsonDecode(res.body));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(),
        firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (picked != null) setState(() => _startDate = picked.toIso8601String().split('T')[0]);
  }

  Future<void> _save() async {
    if (_name.text.isEmpty) return;
    if (widget.member == null && (_packageId == null || _startDate.isEmpty)) {
      if (mounted) showSnack(context, 'Please select package and start date', error: true); return;
    }
    setState(() => _loading = true);
    try {
      if (widget.member != null) {
        await ApiService.put('/paluwagan/members/${widget.member!['id']}',
            {'fullName': _name.text, 'phone': _phone.text, 'address': _address.text, 'status': _status});
      } else {
        await ApiService.post('/paluwagan/members', {
          'fullName': _name.text, 'phone': _phone.text, 'address': _address.text, 'status': _status,
          'paluwaganPackage': {'id': int.parse(_packageId!)}, 'startDate': _startDate,
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(widget.member != null ? 'Edit Member' : 'Add Member',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 8),
        _f(_name, 'Full Name *'),
        _f(_phone, 'Phone', type: TextInputType.phone),
        _f(_address, 'Address'),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: InputDecoration(labelText: 'Status', labelStyle: GoogleFonts.outfit(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          items: ['ACTIVE', 'COMPLETED', 'DROPPED'].map((s) =>
              DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.outfit()))).toList(),
          onChanged: (v) => setState(() => _status = v!),
        ),
        if (widget.member == null) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _packageId,
            decoration: InputDecoration(labelText: 'Package *', labelStyle: GoogleFonts.outfit(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: _packages.where((p) => p['active'] == true).map<DropdownMenuItem<String>>((p) =>
                DropdownMenuItem(value: p['id'].toString(),
                    child: Text('${p['name']} — ${formatPeso(p['weeklyAmount'])}/wk',
                        style: GoogleFonts.outfit()))).toList(),
            onChanged: (v) => setState(() => _packageId = v),
          ),
          const SizedBox(height: 10),
          GestureDetector(onTap: _pickDate,
            child: Container(width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(_startDate.isEmpty ? 'Select Start Date *' : 'Start Date: $_startDate',
                  style: GoogleFonts.outfit(color: _startDate.isEmpty ? Colors.grey : Colors.black)))),
        ],
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 46,
          child: ElevatedButton(onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text(widget.member != null ? 'Update' : 'Add Member',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600)))),
        const SizedBox(height: 20),
      ])),
    );
  }

  Widget _f(TextEditingController c, String l, {TextInputType type = TextInputType.text}) =>
      Padding(padding: const EdgeInsets.only(bottom: 10),
        child: TextField(controller: c, keyboardType: type,
            decoration: InputDecoration(labelText: l, labelStyle: GoogleFonts.outfit(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            style: GoogleFonts.outfit()));
}
