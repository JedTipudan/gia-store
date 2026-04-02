import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/dialogs.dart';

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
    final result = await showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FoodForm(item: item),
    );
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
                      Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No food items yet', style: GoogleFonts.outfit(color: Colors.grey)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        final isActive = item['active'] ?? true;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              Container(width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xFFDCFCE7) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.fastfood_rounded,
                                    color: isActive ? const Color(0xFF16a34a) : Colors.grey)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item['name'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                                if ((item['category'] ?? '').toString().isNotEmpty)
                                  Text(item['category'], style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                                Row(children: [
                                  Text(formatPeso(item['price']), style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold, color: const Color(0xFF16a34a), fontSize: 13)),
                                  const SizedBox(width: 8),
                                  Text('Stock: ${item['stock']}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                                ]),
                              ])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                GestureDetector(
                                  onTap: () => _toggleAvailability(item),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFFDCFCE7) : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(9999)),
                                    child: Text(isActive ? 'Available' : 'Unavailable',
                                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600,
                                            color: isActive ? const Color(0xFF16a34a) : Colors.grey)),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(children: [
                                  _actionBtn(Icons.edit, const Color(0xFFDBEAFE), const Color(0xFF2563eb),
                                      () => _openForm(Map<String, dynamic>.from(item))),
                                  const SizedBox(width: 6),
                                  _actionBtn(Icons.delete, const Color(0xFFFEE2E2), Colors.red,
                                      () => _delete(item)),
                                ]),
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

  Widget _actionBtn(IconData icon, Color bg, Color color, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Container(padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: color)));
}

class _FoodForm extends StatefulWidget {
  final Map? item;
  const _FoodForm({this.item});
  @override
  State<_FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends State<_FoodForm> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _cat = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  bool _active = true, _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _name.text = widget.item!['name'] ?? '';
      _desc.text = widget.item!['description'] ?? '';
      _cat.text = widget.item!['category'] ?? '';
      _price.text = widget.item!['price']?.toString() ?? '';
      _stock.text = widget.item!['stock']?.toString() ?? '0';
      _active = widget.item!['active'] ?? true;
    }
  }

  Future<void> _save() async {
    if (_name.text.isEmpty || _price.text.isEmpty) return;
    setState(() => _loading = true);
    final body = {'name': _name.text, 'description': _desc.text, 'category': _cat.text,
      'price': double.tryParse(_price.text) ?? 0, 'stock': int.tryParse(_stock.text) ?? 0, 'active': _active};
    try {
      if (widget.item != null) await ApiService.put('/food-items/${widget.item!['id']}', body);
      else await ApiService.post('/food-items', body);
      if (mounted) Navigator.pop(context, true);
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(widget.item != null ? 'Edit Food Item' : 'Add Food Item',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 8),
        _f(_name, 'Name *'), _f(_desc, 'Description'), _f(_cat, 'Category'),
        Row(children: [
          Expanded(child: _f(_price, 'Price (₱) *', type: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: _f(_stock, 'Stock', type: TextInputType.number)),
        ]),
        SwitchListTile(value: _active, contentPadding: EdgeInsets.zero,
            title: Text('Available', style: GoogleFonts.outfit()),
            activeColor: const Color(0xFF16a34a),
            onChanged: (v) => setState(() => _active = v)),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, height: 46,
          child: ElevatedButton(onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text(widget.item != null ? 'Update' : 'Add Item',
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
