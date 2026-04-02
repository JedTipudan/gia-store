import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';

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
  List _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
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
        _payments = pRes.statusCode == 200
            ? (jsonDecode(pRes.body) as List).where((p) => p['paid'] == true).toList()
            : [];
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: const Color(0xFF0F2414),
        child: TabBar(
          controller: _tab,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          indicatorColor: const Color(0xFF4ade80),
          labelColor: const Color(0xFF4ade80),
          unselectedLabelColor: Colors.grey[500],
          tabs: [
            Tab(text: 'Food Orders (${_orders.length})'),
            Tab(text: 'Payments (${_payments.length})'),
          ],
        ),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tab, children: [
              _ordersList(),
              _paymentsList(),
            ])),
    ]);
  }

  Widget _ordersList() {
    if (_orders.isEmpty) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.fastfood_outlined, size: 64, color: Colors.grey[700]),
        const SizedBox(height: 12),
        Text('No food orders yet', style: GoogleFonts.outfit(color: Colors.grey[500])),
        const SizedBox(height: 8),
        Text('Order from Today\'s Menu', style: GoogleFonts.outfit(
            fontSize: 12, color: Colors.grey[600])),
      ],
    ));

    return RefreshIndicator(onRefresh: _load,
      child: ListView.builder(padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (_, i) {
          final o = _orders[i];
          final status = o['status'] ?? 'PENDING';
          final statusColors = {'PENDING': Colors.orange, 'CONFIRMED': const Color(0xFF4ade80), 'CANCELLED': Colors.red};
          final color = statusColors[status] ?? Colors.grey;
          final imageUrl = (o['foodItem']?['imageUrl'] ?? '').toString();
          final fullUrl = imageUrl.startsWith('/api')
              ? 'https://gia-store-production.up.railway.app$imageUrl' : imageUrl;

          return Card(margin: const EdgeInsets.only(bottom: 10),
            child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
              // Food image
              Container(width: 56, height: 56,
                decoration: BoxDecoration(color: const Color(0xFF0F2414),
                    borderRadius: BorderRadius.circular(10)),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.isNotEmpty
                    ? Image.network(fullUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.fastfood_rounded,
                            color: Colors.grey))
                    : const Icon(Icons.fastfood_rounded, color: Colors.grey)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o['foodItem']?['name'] ?? '', style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Qty: ${o['quantity']} × ${formatPeso(o['foodItem']?['price'])}',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400])),
                Text(formatDate(o['orderedAt']),
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600])),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatPeso(o['totalPrice']), style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, color: const Color(0xFF4ade80), fontSize: 14)),
                const SizedBox(height: 4),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9999)),
                  child: Text(status, style: GoogleFonts.outfit(
                      fontSize: 10, fontWeight: FontWeight.w600, color: color))),
              ]),
            ])));
        }));
  }

  Widget _paymentsList() {
    if (_payments.isEmpty) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[700]),
        const SizedBox(height: 12),
        Text('No paid payments yet', style: GoogleFonts.outfit(color: Colors.grey[500])),
      ],
    ));

    return RefreshIndicator(onRefresh: _load,
      child: ListView.builder(padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        itemBuilder: (_, i) {
          final p = _payments[i];
          return Card(margin: const EdgeInsets.only(bottom: 8),
            child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFF16a34a).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF4ade80), size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['member']?['paluwaganPackage']?['name'] ?? '',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                Text(p['periodLabel'] ?? 'Week ${p['periodNumber']}',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400])),
                if ((p['paymentMethod'] ?? '').toString().isNotEmpty)
                  Text('via ${p['paymentMethod']}',
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500])),
                Text('Paid: ${formatDate(p['paidAt'])}',
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600])),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatPeso(p['amount']), style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, color: const Color(0xFF4ade80), fontSize: 15)),
                if ((p['receiptNumber'] ?? '').toString().isNotEmpty)
                  Text(p['receiptNumber'], style: GoogleFonts.outfit(
                      fontSize: 9, color: Colors.grey[600])),
              ]),
            ])));
        }));
  }
}
