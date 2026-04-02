import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/food_image.dart';
import '../payment_page.dart';

class CustomerFoodMenu extends StatefulWidget {
  const CustomerFoodMenu({super.key});
  @override
  State<CustomerFoodMenu> createState() => _CustomerFoodMenuState();
}

class _CustomerFoodMenuState extends State<CustomerFoodMenu> {
  List _items = [];
  bool _loading = true;
  String _selectedCategory = 'All';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _load();
    SharedPreferences.getInstance().then((p) =>
        setState(() => _userId = p.getString('userId') ?? ''));
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/food-items/today');
      if (res.statusCode == 200) {
        setState(() { _items = jsonDecode(res.body); _loading = false; });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  List<String> get _categories {
    final cats = _items
        .map((i) => (i['category'] ?? '').toString())
        .where((c) => c.isNotEmpty).toSet().toList();
    return ['All', ...cats];
  }

  List get _filtered => _selectedCategory == 'All'
      ? _items
      : _items.where((i) => i['category'] == _selectedCategory).toList();

  void _orderItem(Map item) async {
    if (_userId.isEmpty) {
      showSnack(context, 'Please login again', error: true); return;
    }

    // Step 1: Confirm order
    final confirmed = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(item['name'] ?? '',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          FoodImage(imageUrl: item['imageUrl'], height: 140, width: double.infinity),
          const SizedBox(height: 12),
          if ((item['description'] ?? '').toString().isNotEmpty)
            Text(item['description'], style: GoogleFonts.outfit(
                fontSize: 13, color: Colors.grey[400])),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Price', style: GoogleFonts.outfit(color: Colors.grey[400])),
            Text(formatPeso(item['price']), style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: const Color(0xFF4ade80), fontSize: 18)),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Order Now', style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
        ],
      )) ?? false;

    if (!confirmed || !mounted) return;

    // Step 2: Place order
    final res = await ApiService.post('/orders', {
      'userId': int.parse(_userId),
      'foodItemId': item['id'],
      'quantity': 1,
    });

    if (!mounted) return;
    if (res.statusCode != 200 && res.statusCode != 201) {
      showSnack(context, 'Failed to place order', error: true); return;
    }

    final order = jsonDecode(res.body);

    // Step 3: Show payment page
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PaymentPage(
        title: item['name'] ?? 'Food Order',
        subtitle: 'Qty: ${order['quantity']} × ${formatPeso(item['price'])}',
        amount: formatPeso(order['totalPrice']),
        paymentId: order['id'].toString(),
        paymentType: 'food',
        onSuccess: () {
          if (mounted) showSnack(context, '✓ Payment submitted! Check History tab.');
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_items.isEmpty) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.restaurant_menu_outlined, size: 72, color: Colors.grey[700]),
        const SizedBox(height: 16),
        Text("No food available today", style: GoogleFonts.outfit(
            fontSize: 16, color: Colors.grey[400])),
        const SizedBox(height: 8),
        Text('Check back later!', style: GoogleFonts.outfit(
            fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 16),
        TextButton.icon(onPressed: _load,
          icon: const Icon(Icons.refresh, color: Color(0xFF4ade80)),
          label: Text('Refresh', style: GoogleFonts.outfit(
              color: const Color(0xFF4ade80)))),
      ],
    ));

    return RefreshIndicator(
      onRefresh: _load,
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            const Icon(Icons.wb_sunny_rounded, color: Color(0xFF4ade80), size: 18),
            const SizedBox(width: 8),
            Text("Today's Menu", style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
            const Spacer(),
            Text('${_filtered.length} items', style: GoogleFonts.outfit(
                fontSize: 12, color: Colors.grey[400])),
          ]),
        ),
        // Category chips
        if (_categories.length > 1)
          SizedBox(height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF16a34a) : const Color(0xFF1A2E1E),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: selected
                          ? const Color(0xFF16a34a) : Colors.grey[700]!)),
                    child: Text(cat, style: GoogleFonts.outfit(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.grey[400])),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        // Grid
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12,
              mainAxisSpacing: 12, childAspectRatio: 0.72),
          itemCount: _filtered.length,
          itemBuilder: (_, i) {
            final item = _filtered[i];
            return GestureDetector(
              onTap: () => _orderItem(item),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2E1E),
                  borderRadius: BorderRadius.circular(14)),
                clipBehavior: Clip.antiAlias,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Stack(children: [
                    FoodImage(imageUrl: item['imageUrl'],
                        height: 120, width: double.infinity,
                        placeholder: Container(height: 120,
                            color: const Color(0xFF0F2414),
                            child: Center(child: Icon(Icons.fastfood_rounded,
                                size: 44, color: Colors.grey[700])))),
                    Positioned(bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.black54,
                        child: Center(child: Text('Tap to Order',
                            style: GoogleFonts.outfit(fontSize: 10,
                                color: Colors.white, fontWeight: FontWeight.w600))))),
                  ]),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item['name'] ?? '', style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        if ((item['category'] ?? '').toString().isNotEmpty)
                          Text(item['category'], style: GoogleFonts.outfit(
                              fontSize: 10, color: Colors.grey[500]), maxLines: 1),
                        if ((item['description'] ?? '').toString().isNotEmpty)
                          Text(item['description'], style: GoogleFonts.outfit(
                              fontSize: 10, color: Colors.grey[600]),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                      ]),
                      Text(formatPeso(item['price']), style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4ade80), fontSize: 15)),
                    ]),
                  )),
                ]),
              ),
            );
          },
        )),
      ]),
    );
  }
}

// ─── Payment Sheet ────────────────────────────────────────────────────────────

