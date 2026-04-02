import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/dialogs.dart';
import '../widgets/food_image.dart';

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
        final counts = <int, int>{};
        for (final pkg in packages) {
          final cRes = await ApiService.get(
              '/paluwagan/packages/${pkg['id']}/enrolled-count');
          if (cRes.statusCode == 200) {
            counts[pkg['id'] as int] = jsonDecode(cRes.body)['enrolled'] as int;
          }
        }
        setState(() { _packages = packages; _enrolledCounts = counts; _loading = false; });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  void _openForm([Map? pkg]) async {
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => _PackageFormScreen(pkg: pkg)));
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
    else showSnack(context, 'Cannot delete — active members enrolled', error: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _packages.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _packages.length,
                      itemBuilder: (_, i) => _packageCard(_packages[i]),
                    ),
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

  Widget _emptyState() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey[300]),
      const SizedBox(height: 16),
      Text('No packages yet', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16)),
      const SizedBox(height: 8),
      Text('Tap + to create your first package',
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
    ]));

  Widget _packageCard(Map pkg) {
    final enrolled = _enrolledCounts[pkg['id'] as int] ?? 0;
    final maxSlots = pkg['maxSlots'] ?? 10;
    final slotsLeft = maxSlots - enrolled;
    final isFull = slotsLeft <= 0;
    final months = pkg['durationMonths'] ?? pkg['durationWeeks'] ?? 0;
    final total = (pkg['weeklyAmount'] ?? 0) * months;
    final progress = maxSlots > 0 ? (enrolled / maxSlots).clamp(0.0, 1.0) : 0.0;
    final isActive = pkg['active'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))]),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          FoodImage(imageUrl: pkg['imageUrl'], height: 160, width: double.infinity,
              placeholder: Container(height: 160,
                decoration: const BoxDecoration(gradient: LinearGradient(
                    colors: [Color(0xFF0A2E14), Color(0xFF16a34a)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: Center(child: Icon(Icons.inventory_2_rounded,
                    size: 56, color: Colors.white.withOpacity(0.4))))),
          Positioned(top: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF16a34a) : Colors.grey[600],
                  borderRadius: BorderRadius.circular(9999)),
              child: Text(isActive ? 'Active' : 'Inactive',
                  style: GoogleFonts.outfit(fontSize: 11,
                      fontWeight: FontWeight.w600, color: Colors.white)))),
          if (isFull)
            Positioned(top: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.red,
                    borderRadius: BorderRadius.circular(9999)),
                child: Text('FULL', style: GoogleFonts.outfit(
                    fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)))),
        ]),
        Padding(padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pkg['name'] ?? '', style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, fontSize: 18)),
            if ((pkg['description'] ?? '').toString().isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 4),
                child: Text(pkg['description'], style: GoogleFonts.outfit(
                    fontSize: 13, color: Colors.grey))),
            const SizedBox(height: 14),
            Row(children: [
              _statChip(Icons.payments_outlined,
                  '${formatPeso(pkg['weeklyAmount'])}/month', const Color(0xFF16a34a)),
              const SizedBox(width: 8),
              _statChip(Icons.calendar_month_rounded,
                  '$months months', const Color(0xFF2563eb)),
              const SizedBox(width: 8),
              _statChip(Icons.account_balance_wallet_outlined,
                  formatPeso(total), const Color(0xFF7c3aed)),
            ]),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Slots', style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w600)),
              Text('$enrolled / $maxSlots${isFull ? " • FULL" : ""}',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600,
                      color: isFull ? Colors.red : const Color(0xFF16a34a))),
            ]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(9999),
              child: LinearProgressIndicator(
                value: progress, minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(
                    isFull ? Colors.red : const Color(0xFF16a34a)))),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _actionBtn('Edit', Icons.edit_outlined,
                  const Color(0xFFDBEAFE), const Color(0xFF2563eb),
                  () => _openForm(Map<String, dynamic>.from(pkg))),
              const SizedBox(width: 8),
              _actionBtn('Delete', Icons.delete_outline,
                  const Color(0xFFFEE2E2), Colors.red, () => _delete(pkg)),
            ]),
          ])),
      ]),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color), const SizedBox(width: 4),
      Text(label, style: GoogleFonts.outfit(
          fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ]));

  Widget _actionBtn(String label, IconData icon, Color bg, Color color, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: color), const SizedBox(width: 6),
            Text(label, style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ])));
}

// ─── Package Form Screen ─────────────────────────────────────────────────────

class _PackageFormScreen extends StatefulWidget {
  final Map? pkg;
  const _PackageFormScreen({this.pkg});
  @override
  State<_PackageFormScreen> createState() => _PackageFormScreenState();
}

class _PackageFormScreenState extends State<_PackageFormScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _amount = TextEditingController();
  final _months = TextEditingController();
  final _slots = TextEditingController();
  bool _active = true;
  bool _loading = false;
  bool _uploading = false;
  String _imageUrl = '';
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    if (widget.pkg != null) {
      _name.text = widget.pkg!['name'] ?? '';
      _desc.text = widget.pkg!['description'] ?? '';
      _amount.text = widget.pkg!['weeklyAmount']?.toString() ?? '';
      // support both old durationWeeks and new durationMonths
      _months.text = (widget.pkg!['durationMonths'] ?? widget.pkg!['durationWeeks'] ?? '').toString();
      _slots.text = widget.pkg!['maxSlots']?.toString() ?? '10';
      _imageUrl = widget.pkg!['imageUrl'] ?? '';
      _active = widget.pkg!['active'] ?? true;
    } else {
      _slots.text = '10';
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        ListTile(leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF16a34a)),
            title: Text('Choose from Gallery', style: GoogleFonts.outfit()),
            onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ListTile(leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF16a34a)),
            title: Text('Take a Photo', style: GoogleFonts.outfit()),
            onTap: () => Navigator.pop(context, ImageSource.camera)),
        const SizedBox(height: 8),
      ])));
    if (source == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75, maxWidth: 800);
    if (picked == null) return;
    setState(() { _pickedImage = File(picked.path); _uploading = true; });
    try {
      final token = await ApiService.getToken();
      final request = http.MultipartRequest('POST',
          Uri.parse('https://gia-store-production.up.railway.app/api/upload/image'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', picked.path,
          contentType: MediaType('image', 'jpeg')));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        setState(() { _imageUrl = jsonDecode(body)['url']; _uploading = false; });
        if (mounted) showSnack(context, 'Image uploaded ✓');
      } else {
        setState(() => _uploading = false);
        if (mounted) showSnack(context, 'Upload failed', error: true);
      }
    } catch (_) {
      setState(() => _uploading = false);
      if (mounted) showSnack(context, 'Upload error', error: true);
    }
  }

  Future<void> _save() async {
    if (_name.text.isEmpty || _amount.text.isEmpty || _months.text.isEmpty) return;
    setState(() => _loading = true);
    final body = {
      'name': _name.text,
      'description': _desc.text,
      'weeklyAmount': double.tryParse(_amount.text) ?? 0,
      'durationMonths': int.tryParse(_months.text) ?? 0,
      // keep durationWeeks for backward compat
      'durationWeeks': int.tryParse(_months.text) ?? 0,
      'maxSlots': int.tryParse(_slots.text) ?? 10,
      'imageUrl': _imageUrl,
      'active': _active,
    };
    try {
      if (widget.pkg != null) {
        await ApiService.put('/paluwagan/packages/${widget.pkg!['id']}', body);
      } else {
        await ApiService.post('/paluwagan/packages', body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final months = int.tryParse(_months.text) ?? 0;
    final amount = double.tryParse(_amount.text) ?? 0;
    final total = amount * months;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pkg != null ? 'Edit Package' : 'New Package',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _loading || _uploading ? null : _save,
            child: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.pkg != null ? 'Update' : 'Save',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600,
                        color: const Color(0xFF16a34a)))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          GestureDetector(
            onTap: _uploading ? null : _pickImage,
            child: Container(
              width: double.infinity, height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _imageUrl.isNotEmpty
                        ? const Color(0xFF16a34a) : Colors.grey[300]!,
                    width: _imageUrl.isNotEmpty ? 2 : 1)),
              clipBehavior: Clip.antiAlias,
              child: _uploading
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const CircularProgressIndicator(color: Color(0xFF16a34a)),
                      const SizedBox(height: 10),
                      Text('Uploading...', style: GoogleFonts.outfit(color: Colors.grey)),
                    ])
                  : _pickedImage != null
                      ? Image.file(_pickedImage!, fit: BoxFit.cover)
                      : _imageUrl.isNotEmpty
                          ? FoodImage(imageUrl: _imageUrl, height: 180, width: double.infinity)
                          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.add_photo_alternate_outlined,
                                  size: 48, color: Color(0xFF16a34a)),
                              const SizedBox(height: 8),
                              Text('Add Package Photo', style: GoogleFonts.outfit(color: Colors.grey)),
                              Text('Gallery or Camera',
                                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                            ]),
            ),
          ),
          Center(child: TextButton.icon(
            onPressed: _uploading ? null : _pickImage,
            icon: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF16a34a)),
            label: Text(_imageUrl.isEmpty ? 'Add Photo' : 'Change Photo',
                style: GoogleFonts.outfit(color: const Color(0xFF16a34a),
                    fontWeight: FontWeight.w600)))),
          const SizedBox(height: 8),
          _field(_name, 'Package Name *'),
          _field(_desc, 'Description'),
          Row(children: [
            Expanded(child: _field(_amount, 'Monthly Amount (₱) *',
                type: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field(_months, 'Duration (months) *',
                type: TextInputType.number)),
          ]),
          _field(_slots, 'Max Slots (members allowed)', type: TextInputType.number),

          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563eb).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2563eb).withOpacity(0.2))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline, color: Color(0xFF2563eb), size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Customers pay once per month, due on the 1st of each month.',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.blue[700]))),
            ])),

          if (total > 0)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF16a34a).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF16a34a).withOpacity(0.2))),
              child: Row(children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: Color(0xFF16a34a), size: 18),
                const SizedBox(width: 8),
                Text('Total: ${formatPeso(total)} over $months month${months > 1 ? 's' : ''}',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600,
                        color: const Color(0xFF16a34a))),
              ])),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _active,
            title: Text('Active (visible to customers)', style: GoogleFonts.outfit()),
            activeColor: const Color(0xFF16a34a),
            onChanged: (v) => setState(() => _active = v)),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType type = TextInputType.text}) =>
      Padding(padding: const EdgeInsets.only(bottom: 12),
        child: TextField(controller: c, keyboardType: type,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              labelText: label, labelStyle: GoogleFonts.outfit(),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E2E20) : const Color(0xFFF4F7F4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14))));
}
