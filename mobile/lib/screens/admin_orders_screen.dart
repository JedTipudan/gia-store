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
    if (res.statusCode == 200) {
      showSnack(context, '✓ Order approved!');
      _load();
    } else {
      showSnack(context, 'Failed to approve', error: true);
    }
  }

  Future<void> _decline(Map order) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Decline Order', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Decline payment from ${order['user']?['fullName'] ?? order['user']?['username']}?',
              style: GoogleFonts.outfit()),
          const SizedBox(height: 12),
          TextField(controller: noteCtrl,
              decoration: InputDecoration(
                labelText: 'Reason (shown to customer)',
                labelStyle: GoogleFonts.outfit(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              style: GoogleFonts.outfit()),
        ]),
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
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12),
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
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9999)),
            child: Text('$count', style: const TextStyle(
                fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
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
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, i) => _orderCard(orders[i], type: type),
      ),
    );
  }

  Widget _orderCard(Map o, {required String type}) {
    final status = o['status'] ?? 'PENDING';
    final Map<String, Color> colors = {
      'PENDING': Colors.orange,
      'SUBMITTED': Colors.blue,
      'CONFIRMED': const Color(0xFF16a34a),
      'DECLINED': Colors.red,
      'CANCELLED': Colors.grey,
    };
    final Map<String, String> labels = {
      'PENDING': '⏳ Waiting for payment',
      'SUBMITTED': '💳 Payment submitted',
      'CONFIRMED': '✓ Approved',
      'DECLINED': '✗ Declined',
      'CANCELLED': 'Cancelled',
    };
    final color = colors[status] ?? Colors.grey;
    final proofUrl = (o['proofImageUrl'] ?? '').toString();
    final fullProofUrl = proofUrl.startsWith('/api')
        ? 'https://gia-store-production.up.railway.app$proofUrl' : proofUrl;
    final isCash = (o['paymentMethod'] ?? '').toString().toLowerCase().contains('cash');

    return Card(margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Food + customer info
          Row(children: [
            FoodImage(imageUrl: o['foodItem']?['imageUrl'],
                height: 52, width: 52,
                placeholder: Container(width: 52, height: 52,
                    decoration: BoxDecoration(color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.fastfood_rounded, color: Colors.grey))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o['foodItem']?['name'] ?? '',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('${o['user']?['fullName'] ?? o['user']?['username'] ?? 'Unknown'}',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              Text('Qty: ${o['quantity']} • ${formatDate(o['orderedAt'])}',
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(formatPeso(o['totalPrice']), style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF16a34a), fontSize: 15)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9999)),
                child: Text(labels[status] ?? status, style: GoogleFonts.outfit(
                    fontSize: 10, fontWeight: FontWeight.w600, color: color))),
            ]),
          ]),

          // Payment info
          if ((o['paymentMethod'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withOpacity(0.15))),
              child: Row(children: [
                Icon(isCash ? Icons.payments_rounded : Icons.phone_android_rounded,
                    size: 16, color: Colors.blue[300]),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Payment: ${o['paymentMethod']}',
                      style: GoogleFonts.outfit(fontSize: 13,
                          fontWeight: FontWeight.w600, color: Colors.blue[300])),
                  if ((o['referenceNumber'] ?? '').toString().isNotEmpty)
                    Text('Ref: ${o['referenceNumber']}',
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                ])),
              ])),
          ],

          // Proof image (only for non-cash)
          if (!isCash && proofUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Payment Receipt:', style: GoogleFonts.outfit(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              Text('Tap to enlarge', style: GoogleFonts.outfit(
                  fontSize: 10, color: Colors.grey)),
            ]),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => showDialog(context: context,
                  builder: (_) => Dialog(
                      child: InteractiveViewer(
                          child: Image.network(fullProofUrl)))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(fullProofUrl,
                    height: 180, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 60,
                        color: Colors.grey[100],
                        child: const Center(child: Icon(Icons.broken_image,
                            color: Colors.grey))))),
            ),
          ],

          // Cash note
          if (isCash && type == 'submitted') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Customer will pay cash in person.',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange))),
              ])),
          ],

          // Approve / Decline buttons for SUBMITTED orders
          if (type == 'submitted') ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _decline(o),
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                label: Text('Decline', style: GoogleFonts.outfit(
                    color: Colors.red, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => _approve(o),
                icon: const Icon(Icons.check, size: 16),
                label: Text('Approve', style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16a34a),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              )),
            ]),
          ],

          // Pending note
          if (type == 'pending') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.hourglass_empty_rounded,
                    color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Waiting for customer to submit payment.',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange))),
              ])),
          ],
        ])));
  }
}
