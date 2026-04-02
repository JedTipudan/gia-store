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
  List _paid = [];
  List _confirmed = [];
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
          _paid = all.where((o) => o['status'] == 'PAID').toList();
          _confirmed = all.where((o) =>
              o['status'] == 'CONFIRMED' || o['status'] == 'CANCELLED').toList();
          _loading = false;
        });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _updateStatus(Map order, String status) async {
    final res = await ApiService.patch2('/orders/${order['id']}/status',
        {'status': status});
    if (!mounted) return;
    if (res.statusCode == 200) {
      showSnack(context, status == 'CONFIRMED'
          ? '✓ Order confirmed!' : 'Order cancelled');
      _load();
    } else {
      showSnack(context, 'Failed to update', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: Theme.of(context).appBarTheme.backgroundColor,
        child: TabBar(
          controller: _tab,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12),
          indicatorColor: const Color(0xFF16a34a),
          labelColor: const Color(0xFF16a34a),
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(child: _tabLabel('Pending', _pending.length, Colors.orange)),
            Tab(child: _tabLabel('Paid', _paid.length, Colors.blue)),
            Tab(child: _tabLabel('Done', _confirmed.length, Colors.grey)),
          ],
        ),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tab, children: [
              _orderList(_pending, showActions: true),
              _orderList(_paid, showProof: true, showConfirm: true),
              _orderList(_confirmed),
            ])),
    ]);
  }

  Widget _tabLabel(String label, int count, Color color) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color,
                borderRadius: BorderRadius.circular(9999)),
            child: Text('$count', style: const TextStyle(
                fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ]);

  Widget _orderList(List orders,
      {bool showActions = false, bool showProof = false, bool showConfirm = false}) {
    if (orders.isEmpty) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.receipt_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 12),
        Text('No orders here', style: GoogleFonts.outfit(color: Colors.grey)),
      ]));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, i) => _orderCard(orders[i],
            showActions: showActions,
            showProof: showProof,
            showConfirm: showConfirm),
      ),
    );
  }

  Widget _orderCard(Map o,
      {bool showActions = false, bool showProof = false, bool showConfirm = false}) {
    final status = o['status'] ?? 'PENDING';
    final Map<String, Color> colors = {
      'PENDING': Colors.orange,
      'PAID': Colors.blue,
      'CONFIRMED': const Color(0xFF16a34a),
      'CANCELLED': Colors.red,
    };
    final color = colors[status] ?? Colors.grey;
    final proofUrl = (o['proofImageUrl'] ?? '').toString();
    final fullProofUrl = proofUrl.startsWith('/api')
        ? 'https://gia-store-production.up.railway.app$proofUrl' : proofUrl;

    return Card(margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Customer + food info
        Row(children: [
          FoodImage(imageUrl: o['foodItem']?['imageUrl'],
              height: 52, width: 52,
              placeholder: Container(width: 52, height: 52,
                  decoration: BoxDecoration(color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.fastfood_rounded, color: Colors.grey))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(o['foodItem']?['name'] ?? '', style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, fontSize: 14)),
            Text('Customer: ${o['user']?['fullName'] ?? o['user']?['username'] ?? ''}',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
            Text('Qty: ${o['quantity']} • ${formatDate(o['orderedAt'])}',
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatPeso(o['totalPrice']), style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: const Color(0xFF16a34a), fontSize: 15)),
            const SizedBox(height: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9999)),
              child: Text(status, style: GoogleFonts.outfit(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color))),
          ]),
        ]),

        // Payment info
        if ((o['paymentMethod'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.payment_rounded, size: 14, color: Colors.blue),
                const SizedBox(width: 6),
                Text('${o['paymentMethod']}',
                    style: GoogleFonts.outfit(fontSize: 13,
                        fontWeight: FontWeight.w600, color: Colors.blue)),
                if ((o['referenceNumber'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text('Ref: ${o['referenceNumber']}',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                ],
              ]),
            ])),
        ],

        // Proof image
        if (showProof && proofUrl.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Payment Receipt:', style: GoogleFonts.outfit(
              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => showDialog(context: context,
                builder: (_) => Dialog(child: InteractiveViewer(
                    child: Image.network(fullProofUrl)))),
            child: ClipRRect(borderRadius: BorderRadius.circular(10),
              child: Image.network(fullProofUrl, height: 160,
                  width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 60,
                      color: Colors.grey[100],
                      child: const Center(child: Icon(Icons.broken_image,
                          color: Colors.grey))))),
          ),
          Text('Tap to view full size', style: GoogleFonts.outfit(
              fontSize: 10, color: Colors.grey)),
        ],

        // Actions
        if (showConfirm) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _updateStatus(o, 'CANCELLED'),
              icon: const Icon(Icons.close, size: 16, color: Colors.red),
              label: Text('Cancel', style: GoogleFonts.outfit(
                  color: Colors.red, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _updateStatus(o, 'CONFIRMED'),
              icon: const Icon(Icons.check, size: 16),
              label: Text('Confirm', style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16a34a),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            )),
          ]),
        ],
        if (showActions) ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.hourglass_empty_rounded,
                  color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Waiting for customer to submit payment',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange))),
            ])),
        ],
      ])));
  }
}
