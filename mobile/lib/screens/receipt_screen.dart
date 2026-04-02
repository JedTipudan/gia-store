import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/dialogs.dart';

class ReceiptScreen extends StatelessWidget {
  final Map payment;
  const ReceiptScreen({super.key, required this.payment});

  void _download(BuildContext context) async {
    final token = await ApiService.getToken();
    final url = 'https://gia-store-production.up.railway.app/api/receipts/${payment['id']}/pdf';
    final uri = Uri.parse(url);
    final headers = {'Authorization': 'Bearer $token'};
    final fullUrl = '$url?token=$token';
    if (await canLaunchUrl(Uri.parse(fullUrl))) {
      await launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication);
    }
  }

  void _share(BuildContext context) {
    final text = '''
🏪 GIA STORE — OFFICIAL RECEIPT

Receipt No: ${payment['receiptNumber'] ?? 'N/A'}
Member: ${payment['member']?['fullName'] ?? 'N/A'}
Package: ${payment['member']?['paluwaganPackage']?['name'] ?? 'N/A'}
Week: ${payment['weekNumber']} of ${payment['member']?['paluwaganPackage']?['durationWeeks'] ?? 'N/A'}
Amount: ${formatPeso(payment['amount'])}
Due Date: ${formatDate(payment['dueDate'])}
Paid On: ${formatDate(payment['paidAt'])}
Status: ✅ PAID

Thank you for your payment!
    ''';
    Share.share(text, subject: 'Receipt - ${payment['receiptNumber']}');
  }

  @override
  Widget build(BuildContext context) {
    final member = payment['member'] ?? {};
    final pkg = member['paluwaganPackage'] ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Receipt', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () => _share(context)),
          IconButton(icon: const Icon(Icons.download), onPressed: () => _download(context)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Receipt card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
                    blurRadius: 12, offset: const Offset(0, 4))]),
            child: Column(children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF16a34a),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(children: [
                  Stack(alignment: Alignment.center, children: [
                    Container(width: 60, height: 60,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16)),
                      child: Stack(alignment: Alignment.center, children: [
                        const Icon(Icons.storefront_rounded, size: 34, color: Colors.white),
                        Positioned(bottom: 6, right: 6,
                          child: Container(width: 18, height: 18,
                            decoration: const BoxDecoration(color: Color(0xFFfbbf24), shape: BoxShape.circle),
                            child: const Icon(Icons.currency_exchange, size: 10, color: Colors.white))),
                      ])),
                  ]),
                  const SizedBox(height: 10),
                  Text('GIA STORE', style: GoogleFonts.outfit(fontSize: 20,
                      fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                  Text('OFFICIAL RECEIPT', style: GoogleFonts.outfit(fontSize: 12,
                      color: Colors.white.withOpacity(0.85), letterSpacing: 1)),
                ]),
              ),
              // Status badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: const Color(0xFFF0FDF4),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle, color: Color(0xFF16a34a), size: 18),
                  const SizedBox(width: 6),
                  Text('PAID', style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                      color: const Color(0xFF16a34a), fontSize: 14, letterSpacing: 1)),
                ]),
              ),
              // Details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  _row('Receipt No.', payment['receiptNumber'] ?? 'N/A'),
                  _divider(),
                  _row('Member Name', member['fullName'] ?? 'N/A'),
                  _divider(),
                  _row('Phone', member['phone'] ?? 'N/A'),
                  _divider(),
                  _row('Package', pkg['name'] ?? 'N/A'),
                  _divider(),
                  _row('Week', 'Week ${payment['weekNumber']} of ${pkg['durationWeeks'] ?? 'N/A'}'),
                  _divider(),
                  _row('Due Date', formatDate(payment['dueDate'])),
                  _divider(),
                  _row('Paid On', formatDate(payment['paidAt'])),
                  _divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Amount Paid', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(formatPeso(payment['amount']), style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 20, color: const Color(0xFF16a34a))),
                    ]),
                  ),
                ]),
              ),
              // Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Column(children: [
                  Text('Thank you for your payment!',
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Container(width: 120, height: 1, color: Colors.grey[400]),
                      const SizedBox(height: 4),
                      Text('Authorized Signature', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                    ]),
                  ]),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          // Action buttons
          Row(children: [
            Expanded(child: _actionBtn(context, Icons.share, 'Share', const Color(0xFF7c3aed), () => _share(context))),
            const SizedBox(width: 12),
            Expanded(child: _actionBtn(context, Icons.download, 'Download PDF', const Color(0xFF2563eb), () => _download(context))),
          ]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
            child: _actionBtn(context, Icons.print, 'Print Receipt', const Color(0xFF16a34a), () => _download(context))),
        ]),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600])),
      Flexible(child: Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
          textAlign: TextAlign.right)),
    ]),
  );

  Widget _divider() => Divider(height: 1, color: Colors.grey[100]);

  Widget _actionBtn(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) =>
      ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );
}
