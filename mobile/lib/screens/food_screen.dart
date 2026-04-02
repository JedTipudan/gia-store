import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FoodForm(item: item),
    );
    if (result == true) _load();
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(context: context,
        builder: (_) => AlertDialog(
          title: Text('Deactivate Item', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Text('Are you sure?', style: GoogleFonts.outfit()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
                    foregroundColor: Colors.white),
                child: const Text('Deactivate')),
          ],
        ));
    if (ok == true) { await ApiService.delete('/food-items/$id'); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? Center(child: Text('No food items yet', style: GoogleFonts.outfit(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shopping_basket, color: Color(0xFF16a34a)),
                            ),
                            title: Text(item['name'] ?? '',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (item['category'] != null)
                                Text(item['category'], style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                              Text('Stock: ${item['stock']}',
                                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                            ]),
                            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(formatPeso(item['price']),
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                                      color: const Color(0xFF16a34a))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item['active'] == true ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(item['active'] == true ? 'Active' : 'Inactive',
                                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600,
                                        color: item['active'] == true ? const Color(0xFF16a34a) : Colors.red)),
                              ),
                            ]),
                            onTap: () => _openForm(Map<String, dynamic>.from(item)),
                            onLongPress: () => _delete(item['id']),
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
  bool _active = true;
  bool _loading = false;

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
    final body = {
      'name': _name.text, 'description': _desc.text,
      'category': _cat.text, 'price': double.tryParse(_price.text) ?? 0,
      'stock': int.tryParse(_stock.text) ?? 0, 'active': _active,
    };
    try {
      if (widget.item != null) {
        await ApiService.put('/food-items/${widget.item!['id']}', body);
      } else {
        await ApiService.post('/food-items', body);
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
          Text(widget.item != null ? 'Edit Food Item' : 'Add Food Item',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _field(_name, 'Name *'),
          _field(_desc, 'Description'),
          _field(_cat, 'Category'),
          Row(children: [
            Expanded(child: _field(_price, 'Price (₱) *',
                type: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field(_stock, 'Stock',
                type: TextInputType.number)),
          ]),
          SwitchListTile(
            value: _active, contentPadding: EdgeInsets.zero,
            title: Text('Active', style: GoogleFonts.outfit()),
            activeColor: const Color(0xFF16a34a),
            onChanged: (v) => setState(() => _active = v),
          ),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(widget.item != null ? 'Update' : 'Add Item',
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
