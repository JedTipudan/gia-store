import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/dashboard');
      if (res.statusCode == 200) {
        setState(() { _data = jsonDecode(res.body); _loading = false; });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data == null) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
        const SizedBox(height: 8),
        Text('Could not load data', style: GoogleFonts.outfit(color: Colors.grey)),
        TextButton(onPressed: _load, child: const Text('Retry')),
      ],
    ));

    final total = (_data!['totalPayments'] ?? 0) as int;
    final unpaid = (_data!['unpaidPayments'] ?? 0) as int;
    final paid = total - unpaid;
    final rate = total > 0 ? paid / total : 0.0;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: GoogleFonts.outfit(fontSize: 13,
                fontWeight: FontWeight.w600, color: Colors.grey[600])),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatCard('Food Items', '${_data!['totalFoodItems']}',
                    Icons.shopping_basket, const Color(0xFF16a34a), const Color(0xFFDCFCE7)),
                _StatCard('Total Members', '${_data!['totalMembers']}',
                    Icons.people, const Color(0xFF2563eb), const Color(0xFFDBEAFE)),
                _StatCard('Active Members', '${_data!['activeMembers']}',
                    Icons.person_pin, const Color(0xFFd97706), const Color(0xFFFEF3C7)),
                _StatCard('Packages', '${_data!['totalPackages']}',
                    Icons.inventory_2, const Color(0xFF7c3aed), const Color(0xFFEDE9FE)),
              ],
            ),
            const SizedBox(height: 16),
            _CollectionCard(
              totalCollected: _data!['totalCollected'],
              paid: paid, total: total, rate: rate,
            ),
            const SizedBox(height: 12),
            _PendingCard(unpaid: unpaid, paid: paid, total: total),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  const _StatCard(this.label, this.value, this.icon, this.color, this.bg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20)),
        const Spacer(),
        Text(value, style: GoogleFonts.outfit(fontSize: 24,
            fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.outfit(fontSize: 11,
            color: Colors.grey[600], fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final dynamic totalCollected;
  final int paid, total;
  final double rate;
  const _CollectionCard({required this.totalCollected, required this.paid,
      required this.total, required this.rate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.trending_up, color: Color(0xFF16a34a), size: 18),
          const SizedBox(width: 8),
          Text('Total Collected', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        Text(formatPeso(totalCollected),
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold,
                color: const Color(0xFF16a34a))),
        Text('$paid of $total payments collected',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: LinearProgressIndicator(
            value: rate, minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF16a34a)),
          ),
        ),
        const SizedBox(height: 4),
        Text('${(rate * 100).round()}% collection rate',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500])),
      ]),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final int unpaid, paid, total;
  const _PendingCard({required this.unpaid, required this.paid, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Text('Pending Payments', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        Text('$unpaid', style: GoogleFonts.outfit(fontSize: 28,
            fontWeight: FontWeight.bold, color: Colors.red)),
        Text('payments awaiting collection',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _Row('Paid', '$paid', const Color(0xFF16a34a)),
          _Row('Unpaid', '$unpaid', Colors.red),
          _Row('Total', '$total', Colors.grey),
        ]),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Row(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
        fontSize: 16, color: color)),
    Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500])),
  ]);
}
