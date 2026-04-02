import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/dialogs.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});
  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  List _packages = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/paluwagan/packages');
      if (res.statusCode == 200) setState(() { _packages = jsonDecode(res.body); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  void _openForm([Map? pkg]) async {
    final result = await showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PackageForm(pkg: pkg),
    );
    if (result == true && mounted) {
      showSnack(context, pkg != null ? 'Package updated!' : 'Package created!');
      _load();
    }
  }

  Future<void> _delete(Map pkg) async {
    final ok = await confirmDelete(context, pkg['name']);
    if (!ok || !mounted) return;
    final res = await ApiService.delete('/paluwagan/packages/${pkg['id']}');
    if (!mounted) return;
    if (res.statusCode == 200) { showSnack(context, 'Package deleted'); _load(); }
    else showSnack(context, 'Cannot delete — members may be using this package', error: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _packages.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No packages yet', style: GoogleFonts.outfit(color: Colors.grey)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _packages.length,
                      itemBuilder: (_, i) {
                        final pkg = _packages[i];
                        final total = (pkg['weeklyAmount'] ?? 0) * (pkg['durationWeeks'] ?? 0);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Expanded(child: Text(pkg['name'] ?? '',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: pkg['active'] == true ? const Color(0xFFDCFCE7) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(9999)),
                                  child: Text(pkg['active'] == true ? 'Active' : 'Inactive',
                                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600,
                                          color: pkg['active'] == true ? const Color(0xFF16a34a) : Colors.grey)),
                                ),
                              ]),
                              if ((pkg['description'] ?? '').toString().isNotEmpty)
                                Padding(padding: const EdgeInsets.only(top: 2),
                                  child: Text(pkg['description'], style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey))),
                              const SizedBox(height: 10),
                              Row(children: [
                                _infoChip(Icons.payments_outlined, '${formatPeso(pkg['weeklyAmount'])}/wk', const Color(0xFF16a34a)),
                                const SizedBox(width: 8),
                                _infoChip(Icons.calendar_today, '${pkg['durationWeeks']} weeks', const Color(0xFF2563eb)),
                                const SizedBox(width: 8),
                                _infoChip(Icons.account_balance_wallet, formatPeso(total), const Color(0xFF7c3aed)),
                              ]),
                              const SizedBox(height: 10),
                              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                _actionBtn('Edit', Icons.edit, const Color(0xFFDBEAFE), const Color(0xFF2563eb),
                                    () => _openForm(Map<String, dynamic>.from(pkg))),
                                const SizedBox(width: 8),
                                _actionBtn('Delete', Icons.delete, const Color(0xFFFEE2E2), Colors.red,
                                    () => _delete(pkg)),
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

  Widget _infoChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ]),
  );

  Widget _actionBtn(String label, IconData icon, Color bg, Color color, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ])));
}

class _PackageForm extends StatefulWidget {
  final Map? pkg;
  const _PackageForm({this.pkg});
  @override
  State<_PackageForm> createState() => _PackageFormState();
}

class _PackageFormState extends State<_PackageForm> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _amount = TextEditingController();
  final _weeks = TextEditingController();
  bool _active = true, _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.pkg != null) {
      _name.text = widget.pkg!['name'] ?? '';
      _desc.text = widget.pkg!['description'] ?? '';
      _amount.text = widget.pkg!['weeklyAmount']?.toString() ?? '';
      _weeks.text = widget.pkg!['durationWeeks']?.toString() ?? '';
      _active = widget.pkg!['active'] ?? true;
    }
  }

  Future<void> _save() async {
    if (_name.text.isEmpty || _amount.text.isEmpty || _weeks.text.isEmpty) return;
    setState(() => _loading = true);
    final body = {'name': _name.text, 'description': _desc.text,
      'weeklyAmount': double.tryParse(_amount.text) ?? 0,
      'durationWeeks': int.tryParse(_weeks.text) ?? 0, 'active': _active};
    try {
      if (widget.pkg != null) await ApiService.put('/paluwagan/packages/${widget.pkg!['id']}', body);
      else await ApiService.post('/paluwagan/packages', body);
      if (mounted) Navigator.pop(context, true);
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final total = (double.tryParse(_amount.text) ?? 0) * (int.tryParse(_weeks.text) ?? 0);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(widget.pkg != null ? 'Edit Package' : 'Add Package',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 8),
        _f(_name, 'Package Name *'), _f(_desc, 'Description'),
        Row(children: [
          Expanded(child: _f(_amount, 'Weekly Amount (₱) *', type: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: _f(_weeks, 'Duration (weeks) *', type: TextInputType.number)),
        ]),
        if (total > 0)
          Container(width: double.infinity, padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
            child: Text('Total Value: ${formatPeso(total)}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF16a34a)))),
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
                : Text(widget.pkg != null ? 'Update' : 'Create',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600)))),
        const SizedBox(height: 20),
      ])),
    );
  }

  Widget _f(TextEditingController c, String l, {TextInputType type = TextInputType.text}) =>
      Padding(padding: const EdgeInsets.only(bottom: 10),
        child: TextField(controller: c, keyboardType: type, onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l, labelStyle: GoogleFonts.outfit(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            style: GoogleFonts.outfit()));
}
