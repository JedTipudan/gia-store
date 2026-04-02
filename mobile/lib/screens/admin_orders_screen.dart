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
  List _confirmed = [];
  List _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
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
          _confirmed = all.where((o) => o['status'] == 'CONFIRMED').toList();
          _history = all.where((o) =>
              o['status'] == 'COMPLETED' ||
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
      showSnack(context, '✓ Payment approved! Order confirmed.');
      _load();
    } else {
      showSnack(context, 'Failed to approve', error: true);
    }
  }

  Future<void> _decline(Map order) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Decline Order', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
            'Decline payment from ${order['user']?['fullName'] ?? order['user']?['username']}?',
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

  Future<void> _markServed(Map order) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF16a34a), size: 22),
          const SizedBox(width: 8),
          Text('Mark as Served', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ]),
        content: Text(
            'Confirm that "${order['foodItem']?['name']}" has been served to ${order['user']?['fullName'] ?? order['user']?['username']}?',
            style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey))),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.restaurant_rounded, size: 16),
            label: Text('Mark Served', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
        ],
      )) ?? false;
    if (!ok) return;
    final res = await ApiService.patch('/orders/${order['id']}/serve');
    if (!mounted) return;
    if (res.statusCode == 200) {
      showSnack(context, '🍽️ Order marked as served!');
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
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 11),
          indicatorColor: const Color(0xFF16a34a),
          labelColor: const Color(0xFF16a34a),
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(child: _tabLabel('Pending', _pending.length, Colors.orange)),
            Tab(child: _tabLabel('Review', _submitted.length, Colors.blue)),
            Tab(child: _tabLabel('Confirmed', _confirmed.length, const Color(0xFF16a34a))),
            Tab(child: _tabLabel('History', _history.length, Colors.grey)),
          ],
        ),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tab, children: [
              _orderList(_pending, type: 'pending'),
              _orderList(_submitted, type: 'review'),
              _orderList(_confirmed, type: 'confirmed'),
              _orderList(_history, type: 'history'),
            ])),
    ]);
  }

  Widget _tabLabel(String label, int count, Color color) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9999)),
            child: Text('$count', style: const TextStyle(
                fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ]);

  Widget _orderList(List orders, {required String type}) {
    if (orders.isEmpty) {
      final msgs = {
        'pending': 'No orders waiting for payment',
        'review': 'No payments to review',
        'confirmed': 'No confirmed orders',
        'history': 'No completed orders yet',
      };
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(_typeIcon(type), size: 64, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(msgs[type] ?? 'No orders',
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (_, i) => _orderCard(orders[i], type: type),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'pending': return Icons.hourglass_empty_rounded;
      case 'review': return Icons.pending_actions_rounded;
      case 'confirmed': return Icons.restaurant_rounded;
      default: return Icons.history_rounded;
    }
  }

  Widget _orderCard(Map o, {required String type}) {
    final status = o['status'] ?? 'PENDING';
    final Map<String, Color> colors = {
      'PENDING': Colors.orange,
      'SUBMITTED': Colors.blue,
      'CONFIRMED': const Color(0xFF16a34a),
      'COMPLETED': Colors.teal,
      'DECLINED': Colors.red,
      'CANCELLED': Colors.grey,
    };
    final Map<String, String> labels = {
      'PENDING': '⏳ Awaiting Payment',
      'SUBMITTED': '💳 Payment Submitted',
      'CONFIRMED': '✓ Confirmed',
      'COMPLETED': '🍽️ Served',
      'DECLINED': '✗ Declined',
      'CANCELLED': 'Cancelled',
    };
    final color = colors[status] ?? Colors.grey;
    final proofUrl = (o['proofImageUrl'] ?? '').toString();
    final fullProofUrl = proofUrl.startsWith('/api')
        ? 'https://gia-store-production.up.railway.app$proofUrl' : proofUrl;
    final isCash = (o['paymentMethod'] ?? '').toString().toLowerCase().contains('cash');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(8),
              child: FoodImage(imageUrl: o['foodItem']?['imageUrl'],
                  height: 48, width: 48,
                  placeholder: Container(width: 48, height: 48,
                      color: Colors.grey[100],
                      child: const Icon(Icons.fastfood_rounded,
                          color: Colors.grey, size: 22)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o['foodItem']?['name'] ?? '',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${o['user']?['fullName'] ?? o['user']?['username'] ?? 'Unknown'}',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              Text('${formatDate(o['orderedAt'])}',
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(formatPeso(o['totalPrice']), style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF16a34a), fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9999)),
                child: Text(labels[status] ?? status, style: GoogleFonts.outfit(
                    fontSize: 9, fontWeight: FontWeight.w600, color: color))),
            ]),
          ]),

          // Payment info
          if ((o['paymentMethod'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(isCash ? Icons.payments_rounded : Icons.phone_android_rounded,
                  size: 13, color: Colors.blue[300]),
              const SizedBox(width: 5),
              Text(o['paymentMethod'], style: GoogleFonts.outfit(
                  fontSize: 12, color: Colors.blue[300], fontWeight: FontWeight.w600)),
              if ((o['referenceNumber'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('• Ref: ${o['referenceNumber']}',
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
              ],
            ]),
          ],

          // Proof image for review tab
          if (type == 'review' && !isCash && proofUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => showDialog(context: context,
                  builder: (_) => Dialog(child: InteractiveViewer(
                      child: Image.network(fullProofUrl)))),
              child: ClipRRect(borderRadius: BorderRadius.circular(10),
                child: Image.network(fullProofUrl,
                    height: 120, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 50,
                        color: Colors.grey[100],
                        child: const Center(child: Icon(Icons.broken_image,
                            color: Colors.grey))))),
            ),
            Text('Tap to enlarge', style: GoogleFonts.outfit(
                fontSize: 9, color: Colors.grey)),
          ],

          // Cash note for review
          if (type == 'review' && isCash) ...[
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 14),
                const SizedBox(width: 6),
                Expanded(child: Text('Customer will pay cash in person.',
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.orange))),
              ])),
          ],

          // Action buttons
          if (type == 'review' || type == 'pending') ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => _decline(o),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: Text('Decline', style: GoogleFonts.outfit(
                    color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13)))),
              if (type == 'review') ...[
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: () => _approve(o),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16a34a),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: Text('Approve', style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600, fontSize: 13)))),
              ],
            ]),
          ],

          // Mark as Served button for confirmed orders
          if (type == 'confirmed') ...[
            const SizedBox(height: 12),
            SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _markServed(o),
                icon: const Icon(Icons.restaurant_rounded, size: 18),
                label: Text('Mark as Served 🍽️', style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0ea5e9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              )),
          ],
        ])));
  }
}
