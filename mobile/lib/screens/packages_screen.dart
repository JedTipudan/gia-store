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
  Map<int, int> _enrolledCounts = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/paluwagan/packages');
      if (res.statusCode == 200) {
        final packages = jsonDecode(res.body) as List;
        // Load enrolled counts for each package
        final counts = <int, int>{};
        for (final pkg in packages) {
          final cRes = await ApiService.get('/paluwagan/packages/${pkg['id']}/enrolled-count');
          if (cRes.statusCode == 200) {
            counts[pkg['id'] as int] = jsonDecode(cRes.body)['enrolled'] as int;
          }
        }
        setState(() { _packages = packages; _enrolledCounts = counts; _loading = false; });
      }
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
    if (res.statusCode == 200) { showSnack(context, 'Package deactivated'); _load(); }
    else showSnack(context, 'Cannot delete — members may be enrolled', error: true);
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
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _packages.length,
                      itemBuilder: (_, i) {
                        final pkg = _packages[i];
                        final enrolled = _enrolledCounts[pkg['id'] as int] ?? 0;
                        final maxSlots = pkg['maxSlots'] ?? 10;
                        final total = (pkg['weeklyAmount'] ?? 0) * (pkg['durationWeeks'] ?? 0);
                        final isFull = enrolled >= maxSlots;
                        final slotProgress = maxSlots > 0 ? enrolled / maxSlots : 0.0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Expanded(child: Text(pkg['name'] ?? '',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: pkg['active'] == true ? const Color(0xFFDCFCE7) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(9999)),
                                  child: Text(pkg['active'] == true ? 'Active' : 'Inactive',
                                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600,
                                          color: pkg['active'] == true ? const Color(0xFF16a34a) : Colors.grey))),
                              ]),
                              if ((pkg['description'] ?? '').toString().isNotEmpty)
                                Padding(padding: const EdgeInsets.only(top: 4),
                                  child: Text(pkg['description'], style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey))),
                              const SizedBox(height: 12),
                              // Info chips
                              Wrap(spacing: 8, runSpacing: 6, children: [
                                _chip('${formatPeso(pkg['weeklyAmount'])}/week', Icons.payments_outlined, const Color(0xFF16a34a)),
                                _chip('${pkg['durationWeeks']} weeks', Icons.calendar_today, const Color(0xFF2563eb)),
                                _chip('Total: ${formatPeso(total)}', Icons.account_balance_wallet, const Color(0xFF7c3aed)),
                              ]),
                              const SizedBox(height: 12),
                              // Slots progress
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text('Slots', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
                                Text('$enrolled / $maxSlots ${isFull ? "• FULL" : "available"}',
                                    style: GoogleFonts.outfit(fontSize: 12,
                                        color: isFull ? Colors.red : const Color(0xFF16a34a),
                                        fontWeight: FontWeight.w600)),
                              ]),
                              const SizedBox(height: 6),
                              ClipRRect(borderRadius: BorderRadius.circular(9999),
                                child: LinearProgressIndicator(
                                  value: slotProgress.clamp(0.0, 1.0), minHeight: 8,
                                  backgroundColor: Colors.grey[100],
                                  valueColor: AlwaysStoppedAnimation(isFull ? Colors.red : const Color(0xFF16a34a)))),
                              const SizedBox(height: 12),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF16a34a),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Add Package', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _chip(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color), const SizedBox(width: 4),
      Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ]));

  Widget _actionBtn(String label, IconData icon, Color bg, Color color, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: color), const SizedBox(width: 4),
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
  final _slots = TextEditingController();
  bool _active = true, _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.pkg != null) {
      _name.text = widget.pkg!['name'] ?? '';
      _desc.text = widget.pkg!['description'] ?? '';
      _amount.text = widget.pkg!['weeklyAmount']?.toString() ?? '';
      _weeks.text = widget.pkg!['durationWeeks']?.toString() ?? '';
      _slots.text = widget.pkg!['maxSlots']?.toString() ?? '10';
      _active = widget.pkg!['active'] ?? true;
    } else {
      _slots.text = '10';
    }
  }

  Future<void> _save() async {
    if (_name.text.isEmpty || _amount.text.isEmpty || _weeks.text.isEmpty) return;
    setState(() => _loading = true);
    final body = {
      'name': _name.text, 'description': _desc.text,
      'weeklyAmount': double.tryParse(_amount.text) ?? 0,
      'durationWeeks': int.tryParse(_weeks.text) ?? 0,
      'maxSlots': int.tryParse(_slots.text) ?? 10,
      'active': _active,
    };
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
        _f(_name, 'Package Name *'),
        _f(_desc, 'Description'),
        Row(children: [
          Expanded(child: _f(_amount, 'Weekly Amount (₱) *', type: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: _f(_weeks, 'Duration (weeks) *', type: TextInputType.number)),
        ]),
        _f(_slots, 'Max Slots (how many members allowed)', type: TextInputType.number),
        if (total > 0)
          Container(width: double.infinity, padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
            child: Text('Total Package Value: ${formatPeso(total)}',
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
