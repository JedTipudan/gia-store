import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MemberForm(member: member),
    );
    if (result == true) _load();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE': return const Color(0xFF16a34a);
      case 'COMPLETED': return const Color(0xFF2563eb);
      default: return Colors.red;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'ACTIVE': return const Color(0xFFDCFCE7);
      case 'COMPLETED': return const Color(0xFFDBEAFE);
      default: return const Color(0xFFFEE2E2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _members.isEmpty
                  ? Center(child: Text('No members yet', style: GoogleFonts.outfit(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _members.length,
                      itemBuilder: (_, i) {
                        final m = _members[i];
                        final status = m['status'] ?? 'ACTIVE';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFDCFCE7),
                              child: Text((m['fullName'] ?? 'M')[0].toUpperCase(),
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                                      color: const Color(0xFF16a34a))),
                            ),
                            title: Text(m['fullName'] ?? '',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (m['phone'] != null)
                                Text(m['phone'], style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                              Text(m['paluwaganPackage']?['name'] ?? '',
                                  style: GoogleFonts.outfit(fontSize: 12,
                                      color: const Color(0xFF16a34a), fontWeight: FontWeight.w500)),
                              Text('Started: ${formatDate(m['startDate'])}',
                                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                            ]),
                            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: _statusBg(status),
                                    borderRadius: BorderRadius.circular(9999)),
                                child: Text(status, style: GoogleFonts.outfit(fontSize: 10,
                                    fontWeight: FontWeight.w600, color: _statusColor(status))),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => PaymentsScreen(memberId: m['id']))),
                                child: Text('View Payments',
                                    style: GoogleFonts.outfit(fontSize: 10,
                                        color: const Color(0xFF2563eb),
                                        decoration: TextDecoration.underline)),
                              ),
                            ]),
                            onTap: () => _openForm(Map<String, dynamic>.from(m)),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF16a34a),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
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
    final picked = await showDatePicker(
      context: context, initialDate: DateTime.now(),
      firstDate: DateTime(2020), lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _startDate = picked.toIso8601String().split('T')[0]);
  }

  Future<void> _save() async {
    if (_name.text.isEmpty) return;
    if (widget.member == null && (_packageId == null || _startDate.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select package and start date')));
      return;
    }
    setState(() => _loading = true);
    try {
      if (widget.member != null) {
        await ApiService.put('/paluwagan/members/${widget.member!['id']}', {
          'fullName': _name.text, 'phone': _phone.text,
          'address': _address.text, 'status': _status,
        });
      } else {
        await ApiService.post('/paluwagan/members', {
          'fullName': _name.text, 'phone': _phone.text,
          'address': _address.text, 'status': _status,
          'paluwaganPackage': {'id': int.parse(_packageId!)},
          'startDate': _startDate,
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.member != null ? 'Edit Member' : 'Add Member',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _field(_name, 'Full Name *'),
          _field(_phone, 'Phone', type: TextInputType.phone),
          _field(_address, 'Address'),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: InputDecoration(labelText: 'Status',
                labelStyle: GoogleFonts.outfit(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            items: ['ACTIVE', 'COMPLETED', 'DROPPED']
                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.outfit())))
                .toList(),
            onChanged: (v) => setState(() => _status = v!),
          ),
          if (widget.member == null) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _packageId,
              decoration: InputDecoration(labelText: 'Package *',
                  labelStyle: GoogleFonts.outfit(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              items: _packages.where((p) => p['active'] == true).map<DropdownMenuItem<String>>((p) =>
                  DropdownMenuItem(value: p['id'].toString(),
                      child: Text('${p['name']} — ${formatPeso(p['weeklyAmount'])}/wk',
                          style: GoogleFonts.outfit()))).toList(),
              onChanged: (v) => setState(() => _packageId = v),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(_startDate.isEmpty ? 'Select Start Date *' : 'Start Date: $_startDate',
                    style: GoogleFonts.outfit(color: _startDate.isEmpty ? Colors.grey : Colors.black)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(widget.member != null ? 'Update' : 'Add Member',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType type = TextInputType.text}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(controller: ctrl, keyboardType: type,
            decoration: InputDecoration(labelText: label,
                labelStyle: GoogleFonts.outfit(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2))),
            style: GoogleFonts.outfit()),
      );
}
