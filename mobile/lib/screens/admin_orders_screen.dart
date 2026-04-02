import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/dialogs.dart';
import '../widgets/food_image.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List _pending = [];
  List _submitted = [];
  List _done = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/orders');
      if (res.statusCode == 200) {
        final all = jsonDecode(res.body) as List;
        setState(() {
          _pending = all.where((o) => o['status'] == 'PENDING').toList();
          _submitted = all.where((o) => o['status'] == 'SUBMITTED').toList();
          _done = all.where((o) =>
              o['status'] == 'CONFIRMED' ||
              o['status'] == 'DECLINED' ||
              o['status'] == 'CANCELLED').toList();
          _loading = false;
        });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _approve(Map order) async {
    final res = await ApiService.patch2('/orders/${order['id']}/status',
        {'status': 'CONFIRMED'});
    if (!mounted) return;
    if (res.statusCode == 200) { showSnack(context, '✓ Order approved!'); _load(); }
    else showSnack(context, 'Failed to approve', error: true);
  }

  Future<void> _decline(Map order) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Decline Order', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Decline order from ${order['user']?['fullName'] ?? order['user']?['username']}?',
            style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('Decline', style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
        ],
      )) ?? false;
    if (!ok) return;
    final res = await ApiService.patch2('/orders/${order['id']}/status',
        {'status': 'DECLINED'});
    if (!mounted) return;
    if (res.statusCode == 200) { showSnack(context, 'Order declined'); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: Theme.of(context).appBarTheme.backgroundColor,
        child: TabBar(
          controller: _tab,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 11),
          indicatorColor: const Color(0xFF16a34a),
          labelColor: const Color(0xFF16a34a),
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(child: _tabLabel('Pending', _pending.length, Colors.orange)),
            Tab(child: _tabLabel('Review', _submitted.length, Colors.blue)),
            Tab(child: _tabLabel('Done', _done.length, Colors.grey)),
          ],
        ),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tab, children: [
              _orderList(_pending, type: 'pending'),
              _orderList(_submitted, type: 'submitted'),
              _orderList(_done, type: 'done'),
            ])),
    ]);
  }

  Widget _tabLabel(String label, int count, Color color) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9999)),
            child: Text('$count', style: const TextStyle(
                fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ]);

  Widget _orderList(List orders, {required String type}) {
    if (orders.isEmpty) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(type == 'submitted' ? Icons.pending_actions_rounded
            : Icons.receipt_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 12),
        Text(type == 'submitted' ? 'No orders awaiting review'
            : type == 'pending' ? 'No pending orders'
            : 'No completed orders',
            style: GoogleFonts.outfit(color: Colors.grey)),
      ]));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (_, i) => _orderCard(orders[i], type: type),
      ),
    );
  }

  Widget _orderCard(Map o, {required String type}) {
    final status = o['status'] ?? 'PENDING';
    final Map<String, Color> colors = {
      'PENDING': Colors.orange, 'SUBMITTED': Colors.blue,
      'CONFIRMED': const Color(0xFF16a34a),
      'DECLINED': Colors.red, 'CANCELLED': Colors.grey,
    };
    final color = colors[status] ?? Colors.grey;
    final proofUrl = (o['proofImageUrl'] ?? '').toString();
    final fullProofUrl = proofUrl.startsWith('/api')
        ? 'https://gia-store-production.up.railway.app$proofUrl' : proofUrl;
    final isCash = (o['paymentMethod'] ?? '').toString().toLowerCase().contains('cash');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Compact header
          Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(8),
              child: FoodImage(imageUrl: o['foodItem']?['imageUrl'],
                  height: 44, width: 44,
                  placeholder: Container(width: 44, height: 44,
                      color: Colors.grey[100],
                      child: const Icon(Icons.fastfood_rounded,
                          color: Colors.grey, size: 20)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o['foodItem']?['name'] ?? '',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${o['user']?['fullName'] ?? o['user']?['username'] ?? ''}',
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(formatPeso(o['totalPrice']), style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, color: const Color(0xFF16a34a), fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9999)),
                child: Text(status, style: GoogleFonts.outfit(
                    fontSize: 9, fontWeight: FontWeight.w600, color: color))),
            ]),
          ]),

          // Payment method
          if ((o['paymentMethod'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(isCash ? Icons.payments_rounded : Icons.phone_android_rounded,
                  size: 13, color: Colors.blue),
              const SizedBox(width: 4),
              Text(o['paymentMethod'], style: GoogleFonts.outfit(
                  fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600)),
              if ((o['referenceNumber'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('• Ref: ${o['referenceNumber']}',
                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
              ],
            ]),
          ],

          // Proof (compact)
          if (!isCash && proofUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => showDialog(context: context,
                  builder: (_) => Dialog(child: InteractiveViewer(
                      child: Image.network(fullProofUrl)))),
              child: ClipRRect(borderRadius: BorderRadius.circular(8),
                child: Image.network(fullProofUrl,
                    height: 100, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 40,
                        color: Colors.grey[100],
                        child: const Center(child: Text('Image error',
                            style: TextStyle(fontSize: 10, color: Colors.grey))))))),
            ),
            Text('Tap to enlarge', style: GoogleFonts.outfit(
                fontSize: 9, color: Colors.grey)),
          ],

          // Actions
          if (type == 'submitted' || type == 'pending') ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => _decline(o),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: Text('Decline', style: GoogleFonts.outfit(
                    color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12)))),
              if (type == 'submitted') ...[
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(
                  onPressed: () => _approve(o),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16a34a),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: Text('Approve', style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600, fontSize: 12)))),
              ],
            ]),
          ],
        ])));
  }
}
