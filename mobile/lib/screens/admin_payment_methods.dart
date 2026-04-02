import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/dialogs.dart';

class AdminPaymentMethodsScreen extends StatefulWidget {
  const AdminPaymentMethodsScreen({super.key});
  @override
  State<AdminPaymentMethodsScreen> createState() => _AdminPaymentMethodsScreenState();
}

class _AdminPaymentMethodsScreenState extends State<AdminPaymentMethodsScreen> {
  List _methods = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('/paluwagan/payment-methods');
    if (res.statusCode == 200) setState(() { _methods = jsonDecode(res.body); _loading = false; });
  }

  void _openForm([Map? method]) async {
    final result = await showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PaymentMethodForm(method: method),
    );
    if (result == true && mounted) {
      showSnack(context, method != null ? 'Payment method updated!' : 'Payment method added!');
      _load();
    }
  }

  Future<void> _delete(Map m) async {
    final ok = await confirmDelete(context, m['name']);
    if (!ok || !mounted) return;
    final res = await ApiService.delete('/paluwagan/payment-methods/${m['id']}');
    if (!mounted) return;
    if (res.statusCode == 200) { showSnack(context, 'Deleted'); _load(); }
    else showSnack(context, 'Failed to delete', error: true);
  }

  IconData _getIcon(String? icon) {
    switch (icon) {
      case 'gcash': return Icons.phone_android_rounded;
      case 'cash': return Icons.payments_rounded;
      case 'bank': return Icons.account_balance_rounded;
      default: return Icons.payment_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Methods', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _methods.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text('No payment methods yet', style: GoogleFonts.outfit(color: Colors.grey)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _methods.length,
                      itemBuilder: (_, i) {
                        final m = _methods[i];
                        return Card(margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(width: 44, height: 44,
                                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                                child: Icon(_getIcon(m['icon']), color: const Color(0xFF16a34a))),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(m['name'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                                if ((m['accountNumber'] ?? '').toString().isNotEmpty && m['accountNumber'] != 'N/A')
                                  Text(m['accountNumber'], style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF16a34a), fontWeight: FontWeight.w600)),
                                if ((m['accountName'] ?? '').toString().isNotEmpty)
                                  Text(m['accountName'], style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                              ])),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: m['active'] == true ? const Color(0xFFDCFCE7) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(9999)),
                                child: Text(m['active'] == true ? 'Active' : 'Inactive',
                                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600,
                                        color: m['active'] == true ? const Color(0xFF16a34a) : Colors.grey))),
                            ]),
                            if ((m['instructions'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(m['instructions'], style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                            ],
                            const SizedBox(height: 10),
                            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                              _btn('Edit', Icons.edit, const Color(0xFFDBEAFE), const Color(0xFF2563eb),
                                  () => _openForm(Map<String, dynamic>.from(m))),
                              const SizedBox(width: 8),
                              _btn('Delete', Icons.delete, const Color(0xFFFEE2E2), Colors.red, () => _delete(m)),
                            ]),
                          ])));
                      }),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF16a34a),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Add Method', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _btn(String label, IconData icon, Color bg, Color color, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: color), const SizedBox(width: 4),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ])));
}

class _PaymentMethodForm extends StatefulWidget {
  final Map? method;
  const _PaymentMethodForm({this.method});
  @override
  State<_PaymentMethodForm> createState() => _PaymentMethodFormState();
}

class _PaymentMethodFormState extends State<_PaymentMethodForm> {
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _acctName = TextEditingController();
  final _instructions = TextEditingController();
  String _icon = 'cash';
  bool _active = true, _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.method != null) {
      _name.text = widget.method!['name'] ?? '';
      _number.text = widget.method!['accountNumber'] ?? '';
      _acctName.text = widget.method!['accountName'] ?? '';
      _instructions.text = widget.method!['instructions'] ?? '';
      _icon = widget.method!['icon'] ?? 'cash';
      _active = widget.method!['active'] ?? true;
    }
  }

  Future<void> _save() async {
    if (_name.text.isEmpty) return;
    setState(() => _loading = true);
    final body = {'name': _name.text, 'accountNumber': _number.text,
      'accountName': _acctName.text, 'instructions': _instructions.text,
      'icon': _icon, 'active': _active};
    try {
      if (widget.method != null) await ApiService.put('/paluwagan/payment-methods/${widget.method!['id']}', body);
      else await ApiService.post('/paluwagan/payment-methods', body);
      if (mounted) Navigator.pop(context, true);
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(widget.method != null ? 'Edit Payment Method' : 'Add Payment Method',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 12),
        // Icon type selector
        Row(children: [
          Text('Type: ', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          ...['gcash', 'cash', 'bank'].map((type) => GestureDetector(
            onTap: () => setState(() => _icon = type),
            child: Container(margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _icon == type ? const Color(0xFF16a34a) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8)),
              child: Text(type.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600,
                  color: _icon == type ? Colors.white : Colors.grey[700]))),
          )),
        ]),
        const SizedBox(height: 12),
        _f(_name, 'Method Name * (e.g. GCash, Cash)'),
        _f(_number, 'Account Number / Contact'),
        _f(_acctName, 'Account Name'),
        _f(_instructions, 'Instructions for customers', maxLines: 3),
        SwitchListTile(value: _active, contentPadding: EdgeInsets.zero,
            title: Text('Active', style: GoogleFonts.outfit()),
            activeColor: const Color(0xFF16a34a),
            onChanged: (v) => setState(() => _active = v)),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, height: 46,
          child: ElevatedButton(onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text(widget.method != null ? 'Update' : 'Add Method',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600)))),
        const SizedBox(height: 20),
      ])),
    );
  }

  Widget _f(TextEditingController c, String l, {int maxLines = 1}) =>
      Padding(padding: const EdgeInsets.only(bottom: 10),
        child: TextField(controller: c, maxLines: maxLines,
            decoration: InputDecoration(labelText: l, labelStyle: GoogleFonts.outfit(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            style: GoogleFonts.outfit()));
}
