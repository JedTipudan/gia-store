import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/food_image.dart';

class CustomerHistory extends StatefulWidget {
  final String userId;
  const CustomerHistory({super.key, required this.userId});
  @override
  State<CustomerHistory> createState() => _CustomerHistoryState();
}

class _CustomerHistoryState extends State<CustomerHistory>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List _orders = [];
  List _allPayments = [];
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
    if (widget.userId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final oRes = await ApiService.get('/orders/user/${widget.userId}');
      final pRes = await ApiService.get('/paluwagan/payments/user/${widget.userId}');
      setState(() {
        _orders = oRes.statusCode == 200 ? jsonDecode(oRes.body) : [];
        _allPayments = pRes.statusCode == 200 ? jsonDecode(pRes.body) : [];
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  // Pending = food orders not yet CONFIRMED + paluwagan payments not yet APPROVED
  List get _pendingOrders => _orders
      .where((o) => o['status'] == 'PENDING' || o['status'] == 'PAID')
      .toList();

  List get _pendingPayments => _allPayments
      .where((p) => p['paid'] != true && p['approvalStatus'] != 'PENDING')
      .toList();

  List get _completedOrders => _orders
      .where((o) => o['status'] == 'CONFIRMED' || o['status'] == 'CANCELLED')
      .toList();

  List get _paidPayments => _allPayments.where((p) => p['paid'] == true).toList();

  int get _totalPending => _pendingOrders.length + _pendingPayments.length;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: const Color(0xFF0F2414),
        child: TabBar(
          controller: _tab,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12),
          indicatorColor: const Color(0xFF4ade80),
          labelColor: const Color(0xFF4ade80),
          unselectedLabelColor: Colors.grey[500],
          tabs: [
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Pending'),
              if (_totalPending > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange,
                      borderRadius: BorderRadius.circular(9999)),
                  child: Text('$_totalPending',
                      style: const TextStyle(fontSize: 10, color: Colors.white,
                          fontWeight: FontWeight.bold))),
              ],
            ])),
            const Tab(text: 'Food Orders'),
            const Tab(text: 'Paluwagan'),
          ],
        ),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(controller: _tab, children: [
                _pendingTab(),
                _foodOrdersTab(),
                _paluwaganTab(),
              ]))),
    ]);
  }

  // ── Pending Tab ──────────────────────────────────────────────────────────
  Widget _pendingTab() {
    if (_pendingOrders.isEmpty && _pendingPayments.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF4ade80)),
        const SizedBox(height: 12),
        Text('All caught up!', style: GoogleFonts.outfit(
            color: Colors.grey[400], fontSize: 16)),
        const SizedBox(height: 8),
        Text('No pending orders or payments', style: GoogleFonts.outfit(
            fontSize: 12, color: Colors.grey[600])),
      ]));
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      if (_pendingOrders.isNotEmpty) ...[
        _sectionHeader('Food Orders', Icons.fastfood_rounded, Colors.orange),
        const SizedBox(height: 8),
        ..._pendingOrders.map((o) => _orderCard(o, showStatus: true)),
        const SizedBox(height: 16),
      ],
      if (_pendingPayments.isNotEmpty) ...[
        _sectionHeader('Paluwagan Payments', Icons.receipt_long_rounded, Colors.blue[300]!),
        const SizedBox(height: 8),
        ..._pendingPayments.map((p) => _paymentCard(p)),
      ],
    ]);
  }

  // ── Food Orders Tab ──────────────────────────────────────────────────────
  Widget _foodOrdersTab() {
    if (_orders.isEmpty) return _emptyState(
        Icons.fastfood_outlined, 'No food orders yet', "Order from Today's Menu");
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (_, i) => _orderCard(_orders[i]));
  }

  // ── Paluwagan Tab ────────────────────────────────────────────────────────
  Widget _paluwaganTab() {
    if (_allPayments.isEmpty) return _emptyState(
        Icons.receipt_long_outlined, 'No paluwagan payments yet',
        'Apply for a package first');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allPayments.length,
      itemBuilder: (_, i) => _paymentCard(_allPayments[i]));
  }

  // ── Cards ────────────────────────────────────────────────────────────────
  Widget _orderCard(Map o, {bool showStatus = false}) {
    final status = o['status'] ?? 'PENDING';
    final Map<String, Color> statusColors = {
      'PENDING': Colors.orange,
      'PAID': Colors.blue[300]!,
      'CONFIRMED': const Color(0xFF4ade80),
      'CANCELLED': Colors.red,
    };
    final Map<String, String> statusLabels = {
      'PENDING': '⏳ Pending',
      'PAID': '💳 Payment Submitted',
      'CONFIRMED': '✓ Confirmed',
      'CANCELLED': '✗ Cancelled',
    };
    final color = statusColors[status] ?? Colors.grey;

    return Card(margin: const EdgeInsets.only(bottom: 10),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 52, height: 52,
            decoration: BoxDecoration(color: const Color(0xFF0F2414),
                borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            child: FoodImage(imageUrl: o['foodItem']?['imageUrl'],
                height: 52, width: 52,
                placeholder: const Icon(Icons.fastfood_rounded, color: Colors.grey))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(o['foodItem']?['name'] ?? '', style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
            Text('Qty: ${o['quantity']} × ${formatPeso(o['foodItem']?['price'])}',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400])),
            Text(formatDate(o['orderedAt']),
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600])),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatPeso(o['totalPrice']), style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: const Color(0xFF4ade80), fontSize: 15)),
            const SizedBox(height: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9999)),
              child: Text(statusLabels[status] ?? status, style: GoogleFonts.outfit(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color))),
          ]),
        ]),
        if ((o['paymentMethod'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.payment_rounded, size: 14, color: Colors.blue),
              const SizedBox(width: 6),
              Text('Paid via ${o['paymentMethod']}',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.blue[300])),
              if ((o['referenceNumber'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('Ref: ${o['referenceNumber']}',
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500])),
              ],
            ])),
        ],
        if (status == 'PENDING')
          Padding(padding: const EdgeInsets.only(top: 8),
            child: Text('Waiting for admin to confirm your order',
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.orange.withOpacity(0.8)))),
        if (status == 'PAID')
          Padding(padding: const EdgeInsets.only(top: 8),
            child: Text('Payment submitted — waiting for admin approval',
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.blue[300]))),
      ])));
  }

  Widget _paymentCard(Map p) {
    final isPaid = p['paid'] == true;
    final status = p['approvalStatus'] ?? 'PENDING';
    final Map<String, Color> statusColors = {
      'PENDING': Colors.grey,
      'SUBMITTED': Colors.orange,
      'APPROVED': const Color(0xFF4ade80),
      'REJECTED': Colors.red,
    };
    final color = isPaid ? const Color(0xFF4ade80) : (statusColors[status] ?? Colors.grey);
    final label = isPaid ? '✓ Paid' : status == 'SUBMITTED'
        ? '💳 Submitted' : status == 'REJECTED' ? '✗ Rejected' : '⏳ Unpaid';

    return Card(margin: const EdgeInsets.only(bottom: 8),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(isPaid ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
                color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p['member']?['paluwaganPackage']?['name'] ?? '',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            Text(p['periodLabel'] ?? 'Week ${p['periodNumber']}',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400])),
            Text('Due: ${formatDate(p['dueDate'])}',
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600])),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatPeso(p['amount']), style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: color, fontSize: 15)),
            const SizedBox(height: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9999)),
              child: Text(label, style: GoogleFonts.outfit(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color))),
          ]),
        ]),
        if (status == 'REJECTED' && (p['adminNote'] ?? '').toString().isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 8),
            child: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('Rejected: ${p['adminNote']}',
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.red)))),
      ])));
  }

  Widget _sectionHeader(String title, IconData icon, Color color) =>
      Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.outfit(fontSize: 13,
            fontWeight: FontWeight.w600, color: color)),
      ]);

  Widget _emptyState(IconData icon, String title, String sub) =>
      Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 64, color: Colors.grey[700]),
        const SizedBox(height: 12),
        Text(title, style: GoogleFonts.outfit(color: Colors.grey[500])),
        const SizedBox(height: 8),
        Text(sub, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
      ]));
}
