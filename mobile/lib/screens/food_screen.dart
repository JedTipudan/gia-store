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

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});
  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  List _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/food-items');
      if (res.statusCode == 200) setState(() { _items = jsonDecode(res.body); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  void _openForm([Map? item]) async {
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => _FoodFormScreen(item: item)));
    if (result == true && mounted) {
      showSnack(context, item != null ? 'Food item updated!' : 'Food item added!');
      _load();
    }
  }

  Future<void> _delete(Map item) async {
    final ok = await confirmDelete(context, item['name']);
    if (!ok || !mounted) return;
    final res = await ApiService.delete('/food-items/${item['id']}');
    if (!mounted) return;
    if (res.statusCode == 200) { showSnack(context, 'Item deleted'); _load(); }
    else showSnack(context, 'Failed to delete', error: true);
  }

  Future<void> _toggleAvailability(Map item) async {
    final updated = Map<String, dynamic>.from(item);
    updated['active'] = !(item['active'] ?? true);
    await ApiService.put('/food-items/${item['id']}', updated);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Image.asset('assets/logo.jpg', width: 80, height: 80),
                      const SizedBox(height: 16),
                      Text('No food items yet', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Tap + to add your first item', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                    ]))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        final isActive = item['active'] ?? true;

                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Stack(children: [
                              Container(height: 120, width: double.infinity,
                                color: isActive ? const Color(0xFFDCFCE7) : Colors.grey[100],
                                child: FoodImage(
                                  imageUrl: item['imageUrl'],
                                  height: 120, width: double.infinity,
                                  placeholder: _foodIcon(isActive),
                                )),
                              Positioned(top: 8, right: 8,
                                child: GestureDetector(
                                  onTap: () => _toggleAvailability(item),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFF16a34a) : Colors.grey[600],
                                      borderRadius: BorderRadius.circular(9999)),
                                    child: Text(isActive ? 'Available' : 'Unavailable',
                                        style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ),
                                )),
                              // Today badge
                              Positioned(top: 8, left: 8,
                                child: GestureDetector(
                                  onTap: () async {
                                    await ApiService.patch('/food-items/${item['id']}/toggle-today');
                                    _load();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (item['availableToday'] ?? false)
                                          ? Colors.orange : Colors.black54,
                                      borderRadius: BorderRadius.circular(9999)),
                                    child: Text((item['availableToday'] ?? false) ? '☀ Today' : '+ Today',
                                        style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ),
                                )),
                            ]),
                            Expanded(child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(item['name'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if ((item['category'] ?? '').toString().isNotEmpty)
                                    Text(item['category'], style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey), maxLines: 1),
                                  Text(formatPeso(item['price']), style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold, color: const Color(0xFF16a34a), fontSize: 14)),
                                  Text('Stock: ${item['stock']}', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
                                ]),
                                Row(children: [
                                  Expanded(child: _btn(Icons.edit, const Color(0xFFDBEAFE), const Color(0xFF2563eb),
                                      () => _openForm(Map<String, dynamic>.from(item)))),
                                  const SizedBox(width: 6),
                                  Expanded(child: _btn(Icons.delete, const Color(0xFFFEE2E2), Colors.red,
                                      () => _delete(item))),
                                ]),
                              ]),
                            )),
                          ]),
                        );
                      }),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF16a34a),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Add Food', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _placeholder(bool isActive) => Center(
      child: Icon(Icons.fastfood_rounded, size: 48, color: isActive ? const Color(0xFF16a34a) : Colors.grey[400]));

  Widget _btn(IconData icon, Color bg, Color color, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Container(padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: color)));
}

class _FoodFormScreen extends StatefulWidget {
  final Map? item;
  const _FoodFormScreen({this.item});
  @override
  State<_FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends State<_FoodFormScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _cat = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  bool _active = true, _loading = false, _uploading = false;
  bool _availableToday = false;
  String _imageUrl = '';
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _name.text = widget.item!['name'] ?? '';
      _desc.text = widget.item!['description'] ?? '';
      _cat.text = widget.item!['category'] ?? '';
      _price.text = widget.item!['price']?.toString() ?? '';
      _stock.text = widget.item!['stock']?.toString() ?? '0';
      _imageUrl = widget.item!['imageUrl'] ?? '';
      _active = widget.item!['active'] ?? true;
      _availableToday = widget.item!['availableToday'] ?? false;
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        ListTile(leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF16a34a)),
            title: Text('Choose from Gallery', style: GoogleFonts.outfit()),
            onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ListTile(leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF16a34a)),
            title: Text('Take a Photo', style: GoogleFonts.outfit()),
            onTap: () => Navigator.pop(context, ImageSource.camera)),
        const SizedBox(height: 8),
      ])),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
    if (picked == null) return;

    setState(() { _pickedImage = File(picked.path); _uploading = true; });

    try {
      final token = await ApiService.getToken();
      final request = http.MultipartRequest(
          'POST', Uri.parse('https://gia-store-production.up.railway.app/api/upload/image'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', picked.path,
          contentType: MediaType('image', 'jpeg')));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      setState(() { _imageUrl = data['url']; _uploading = false; });
      if (mounted) showSnack(context, 'Image uploaded ✓');
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) showSnack(context, 'Upload failed', error: true);
    }
  }

  Future<void> _save() async {
    if (_name.text.isEmpty || _price.text.isEmpty) return;
    setState(() => _loading = true);
    final body = {
      'name': _name.text, 'description': _desc.text, 'category': _cat.text,
      'price': double.tryParse(_price.text) ?? 0, 'stock': int.tryParse(_stock.text) ?? 0,
      'imageUrl': _imageUrl, 'active': _active, 'availableToday': _availableToday,
    };
    try {
      if (widget.item != null) await ApiService.put('/food-items/${widget.item!['id']}', body);
      else await ApiService.post('/food-items', body);
      if (mounted) Navigator.pop(context, true);
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item != null ? 'Edit Food Item' : 'Add Food Item',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _loading || _uploading ? null : _save,
            child: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.item != null ? 'Update' : 'Save',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF16a34a))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image picker
          GestureDetector(
            onTap: _uploading ? null : _pickImage,
            child: Container(
              width: double.infinity, height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100], borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!)),
              clipBehavior: Clip.antiAlias,
              child: _uploading
                  ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CircularProgressIndicator(color: Color(0xFF16a34a)),
                      SizedBox(height: 12),
                      Text('Uploading...'),
                    ]))
                  : _pickedImage != null
                      ? Image.file(_pickedImage!, fit: BoxFit.cover)
                      : _imageUrl.isNotEmpty
                          ? FoodImage(imageUrl: _imageUrl, height: 200, width: double.infinity)
                          : _imgPlaceholder(),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: TextButton.icon(
            onPressed: _uploading ? null : _pickImage,
            icon: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF16a34a)),
            label: Text(_imageUrl.isEmpty ? 'Add Photo from Gallery or Camera' : 'Change Photo',
                style: GoogleFonts.outfit(color: const Color(0xFF16a34a), fontWeight: FontWeight.w600)),
          )),
          const SizedBox(height: 16),
          _f(_name, 'Food Name *'),
          _f(_desc, 'Description'),
          _f(_cat, 'Category (e.g. Rice, Viand, Snack)'),
          Row(children: [
            Expanded(child: _f(_price, 'Price (₱) *', type: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _f(_stock, 'Stock', type: TextInputType.number)),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _active,
            title: Text('Available for customers', style: GoogleFonts.outfit()),
            activeColor: const Color(0xFF16a34a),
            onChanged: (v) => setState(() => _active = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _availableToday,
            title: Text('Show on Today\'s Menu ☀️', style: GoogleFonts.outfit()),
            subtitle: Text('Customers will see this today', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
            activeColor: Colors.orange,
            onChanged: (v) => setState(() => _availableToday = v),
          ),
        ]),
      ),
    );
  }

  Widget _imgPlaceholder() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.add_photo_alternate_outlined, size: 52, color: Color(0xFF16a34a)),
    const SizedBox(height: 8),
    Text('Tap to add food photo', style: GoogleFonts.outfit(color: Colors.grey)),
    Text('Gallery or Camera', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
  ]);

  Widget _f(TextEditingController c, String l, {TextInputType type = TextInputType.text}) =>
      Padding(padding: const EdgeInsets.only(bottom: 12),
        child: TextField(controller: c, keyboardType: type,
            decoration: InputDecoration(labelText: l, labelStyle: GoogleFonts.outfit(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            style: GoogleFonts.outfit()));
}
