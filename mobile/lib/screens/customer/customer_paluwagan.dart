import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/dialogs.dart';

class CustomerPaluwagan extends StatefulWidget {
  final String userId;
  const CustomerPaluwagan({super.key, required this.userId});
  @override
  State<CustomerPaluwagan> createState() => _CustomerPaluwaganState();
}

class _CustomerPaluwaganState extends State<CustomerPaluwagan> {
  List _members = [];
  Map<int, List> _paymentsByMember = {};
  bool _loading = true;

  static const _primary = Color(0xFF22c55e);
  static const _card = Color(0xFF162018);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (widget.userId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final mRes = await ApiService.get('/paluwagan/members/user/${widget.userId}');
      if (mRes.statusCode == 200) {
        final members = jsonDecode(mRes.body) as List;
        final paymentsMap = <int, List>{};
        for (final m in members) {
          if (m['status'] == 'ACTIVE') {
            final pRes = await ApiService.get('/paluwagan/payments/member/${m['id']}');
            if (pRes.statusCode == 200) {
              paymentsMap[m['id'] as int] = jsonDecode(pRes.body);
            }
          }
        }
        setState(() {
          _members = members;
          _paymentsByMember = paymentsMap;
          _loading = false;
        });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(
        child: CircularProgressIndicator(color: _primary));

    if (_members.isEmpty) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.groups_outlined, size: 72, color: Colors.grey[700]),
        const SizedBox(height: 16),
        Text('No paluwagan enrollment yet',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[400])),
        const SizedBox(height: 8),
        Text('Go to Packages tab to apply',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600])),
      ]));

    return RefreshIndicator(
      onRefresh: _load,
      color: _primary,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        ..._members.map((m) => _enrollmentSection(m)),
      ]),
    );
  }

  Widget _enrollmentSection(Map m) {
    final status = m['status'] ?? 'PENDING';
    final pkg = m['paluwaganPackage'] ?? {};
    final payments = _paymentsByMember[m['id'] as int] ?? [];
    final paidCount = payments.where((p) => p['paid'] == true).length;
    final total = payments.length;
    final progress = total > 0 ? paidCount / total : 0.0;

    // Find next unpaid payment
    final nextUnpaid = payments.where((p) =>
        p['paid'] == false && p['approvalStatus'] == 'PENDING').toList();
    final submittedPayments = payments.where((p) =>
        p['approvalStatus'] == 'SUBMITTED').toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor(status).withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _statusColor(status).withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pkg['name'] ?? '', style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.payments_outlined, size: 13, color: _statusColor(status)),
                const SizedBox(width: 4),
                Text('${formatPeso(pkg['weeklyAmount'])}/week',
                    style: GoogleFonts.outfit(fontSize: 12,
                        color: _statusColor(status), fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('${pkg['durationWeeks']} weeks',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400])),
              ]),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9999)),
              child: Text(status, style: GoogleFonts.outfit(
                  fontSize: 11, fontWeight: FontWeight.bold,
                  color: _statusColor(status)))),
          ]),
        ),

        Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [

          // PENDING state
          if (status == 'PENDING')
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Your application is being reviewed by the admin.',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange))),
              ])),

          // REJECTED state
          if (status == 'REJECTED')
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Text('Application rejected', style: GoogleFonts.outfit(
                      fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                ]),
                if ((m['adminNote'] ?? '').toString().isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 4),
                    child: Text('Reason: ${m['adminNote']}',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: Colors.red.withOpacity(0.8)))),
              ])),

          // ACTIVE state
          if (status == 'ACTIVE') ...[
            // Payment tracker
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Payment Progress', style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[400])),
              Text('$paidCount / $total paid', style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.bold, color: _primary)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(9999),
              child: LinearProgressIndicator(
                value: progress, minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation(_primary))),
            const SizedBox(height: 4),
            Text('${(progress * 100).round()}% complete',
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500])),
            const SizedBox(height: 16),

            // Submitted waiting
            if (submittedPayments.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.2))),
                child: Row(children: [
                  const Icon(Icons.hourglass_empty_rounded,
                      color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text('${submittedPayments.length} payment${submittedPayments.length > 1 ? 's' : ''} waiting for admin approval',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange)),
                ])),

            // Next payment due — PAY NOW button
            if (nextUnpaid.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primary.withOpacity(0.25))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(nextUnpaid.first['periodLabel'] ?? 'Week ${nextUnpaid.first['periodNumber']}',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                              color: Colors.white, fontSize: 14)),
                      Text('Due: ${formatDate(nextUnpaid.first['dueDate'])}',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400])),
                    ]),
                    Text(formatPeso(nextUnpaid.first['amount']),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold,
                            color: _primary, fontSize: 20)),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showPaymentSheet(nextUnpaid.first),
                      icon: const Icon(Icons.payment_rounded, size: 18),
                      label: Text('Pay Now',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                    )),
                ])),
              const SizedBox(height: 16),
            ],

            // All payments list
            Text('All Payments', style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[400])),
            const SizedBox(height: 8),
            ...payments.map((p) => _paymentRow(p)),
          ],
        ])),
      ]),
    );
  }

  Widget _paymentRow(Map p) {
    final isPaid = p['paid'] == true;
    final status = p['approvalStatus'] ?? 'PENDING';
    Color color;
    IconData icon;
    String label;

    if (isPaid) {
      color = _primary; icon = Icons.check_circle_rounded; label = 'Paid';
    } else if (status == 'SUBMITTED') {
      color = Colors.orange; icon = Icons.hourglass_empty_rounded; label = 'Submitted';
    } else if (status == 'REJECTED') {
      color = Colors.red; icon = Icons.cancel_rounded; label = 'Rejected';
    } else {
      color = Colors.grey; icon = Icons.radio_button_unchecked; label = 'Unpaid';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(isPaid ? 0.2 : 0.1))),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p['periodLabel'] ?? 'Week ${p['periodNumber']}',
              style: GoogleFonts.outfit(fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isPaid ? Colors.white : Colors.grey[400])),
          Text('Due: ${formatDate(p['dueDate'])}',
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[600])),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(formatPeso(p['amount']), style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9999)),
            child: Text(label, style: GoogleFonts.outfit(
                fontSize: 9, fontWeight: FontWeight.w600, color: color))),
        ]),
      ]),
    );
  }

  void _showPaymentSheet(Map payment) async {
    List methods = [];
    final methodRes = await ApiService.get('/paluwagan/payment-methods/active');
    if (methodRes.statusCode == 200) methods = jsonDecode(methodRes.body);
    if (!mounted) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PaymentSheet(
        payment: payment, methods: methods,
        onSubmitted: () {
          _load();
          if (mounted) showSnack(context, '✓ Payment submitted! Waiting for admin approval.');
        }),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'ACTIVE': return _primary;
      case 'PENDING': return Colors.orange;
      case 'REJECTED': return Colors.red;
      case 'COMPLETED': return Colors.blue[300]!;
      default: return Colors.grey;
    }
  }
}

// ─── Payment Sheet ────────────────────────────────────────────────────────────

class _PaymentSheet extends StatefulWidget {
  final Map payment;
  final List methods;
  final VoidCallback onSubmitted;
  const _PaymentSheet({required this.payment, required this.methods,
      required this.onSubmitted});
  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  String? _selectedMethod;
  Map? _selectedMethodData;
  final _refCtrl = TextEditingController();
  File? _proofImage;
  String _uploadedUrl = '';
  bool _uploading = false;
  bool _submitting = false;

  bool get _isCash =>
      _selectedMethodData?['icon'] == 'cash' ||
      (_selectedMethod?.toLowerCase().contains('cash') ?? false);
  bool get _needsProof => !_isCash;

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context, backgroundColor: const Color(0xFF1A2E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF4ade80)),
          title: Text('Choose from Gallery', style: GoogleFonts.outfit(color: Colors.white)),
          onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ListTile(
          leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF4ade80)),
          title: Text('Take a Photo', style: GoogleFonts.outfit(color: Colors.white)),
          onTap: () => Navigator.pop(context, ImageSource.camera)),
        const SizedBox(height: 8),
      ])));
    if (source == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75, maxWidth: 800);
    if (picked == null) return;
    setState(() { _proofImage = File(picked.path); _uploading = true; });
    try {
      final token = await ApiService.getToken();
      final request = http.MultipartRequest('POST',
          Uri.parse('https://gia-store-production.up.railway.app/api/upload/image'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', picked.path,
          contentType: MediaType('image', 'jpeg')));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        setState(() { _uploadedUrl = jsonDecode(body)['url']; _uploading = false; });
      } else {
        setState(() => _uploading = false);
        if (mounted) showSnack(context, 'Upload failed', error: true);
      }
    } catch (_) { setState(() => _uploading = false); }
  }

  Future<void> _submit() async {
    if (_selectedMethod == null) {
      showSnack(context, 'Please select a payment method', error: true); return;
    }
    if (_needsProof && _uploadedUrl.isEmpty) {
      showSnack(context, 'Please upload your payment receipt photo', error: true); return;
    }
    setState(() => _submitting = true);
    final res = await ApiService.patch2(
        '/paluwagan/payments/${widget.payment['id']}/submit-proof', {
      'proofImageUrl': _needsProof ? _uploadedUrl : '',
      'paymentMethod': _selectedMethod,
      'referenceNumber': _needsProof ? _refCtrl.text.trim() : '',
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.statusCode == 200) {
      Navigator.pop(context);
      widget.onSubmitted();
    } else {
      showSnack(context, 'Failed to submit. Try again.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Submit Payment', style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('${widget.payment['periodLabel'] ?? 'Week ${widget.payment['periodNumber']}'} — ${formatPeso(widget.payment['amount'])}',
                style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13)),
          ]),
          IconButton(icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 20),

        // Method selector
        Align(alignment: Alignment.centerLeft,
          child: Text('Select Payment Method', style: GoogleFonts.outfit(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[400]))),
        const SizedBox(height: 10),
        ...widget.methods.map((m) {
          final selected = _selectedMethod == m['name'];
          return GestureDetector(
            onTap: () => setState(() {
              _selectedMethod = m['name'];
              _selectedMethodData = m;
              _proofImage = null;
              _uploadedUrl = '';
              _refCtrl.clear();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF16a34a).withOpacity(0.15)
                    : const Color(0xFF0F2414),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: selected ? const Color(0xFF16a34a) : Colors.grey[800]!,
                    width: selected ? 2 : 1)),
              child: Row(children: [
                Container(width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF16a34a).withOpacity(0.2)
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(
                    m['icon'] == 'gcash' ? Icons.phone_android_rounded
                        : m['icon'] == 'bank' ? Icons.account_balance_rounded
                        : Icons.payments_rounded,
                    color: selected ? const Color(0xFF4ade80) : Colors.grey[400],
                    size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m['name'] ?? '', style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : Colors.grey[300])),
                  if ((m['accountNumber'] ?? '').toString().isNotEmpty &&
                      m['accountNumber'] != 'N/A')
                    Text(m['accountNumber'], style: GoogleFonts.outfit(
                        fontSize: 13, color: const Color(0xFF4ade80),
                        fontWeight: FontWeight.w600)),
                  if ((m['accountName'] ?? '').toString().isNotEmpty)
                    Text(m['accountName'], style: GoogleFonts.outfit(
                        fontSize: 12, color: Colors.grey[500])),
                ])),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF4ade80), size: 20),
              ]),
            ),
          );
        }),

        // Instructions
        if (_selectedMethodData != null &&
            (_selectedMethodData!['instructions'] ?? '').toString().isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_selectedMethodData!['instructions'],
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.blue[300]))),
            ])),

        // Online: ref + photo
        if (_selectedMethod != null && _needsProof) ...[
          TextField(
            controller: _refCtrl,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Reference / Transaction Number',
              labelStyle: GoogleFonts.outfit(color: Colors.grey[500]),
              filled: true, fillColor: const Color(0xFF0F2414),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4ade80), width: 2)))),
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerLeft,
            child: Text('Upload Payment Receipt *', style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[400]))),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _uploading ? null : _pickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity, height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF0F2414),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _uploadedUrl.isNotEmpty
                        ? const Color(0xFF4ade80) : Colors.grey[700]!,
                    width: _uploadedUrl.isNotEmpty ? 2 : 1)),
              clipBehavior: Clip.antiAlias,
              child: _uploading
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const CircularProgressIndicator(color: Color(0xFF4ade80)),
                      const SizedBox(height: 10),
                      Text('Uploading...', style: GoogleFonts.outfit(color: Colors.grey)),
                    ])
                  : _proofImage != null
                      ? Stack(fit: StackFit.expand, children: [
                          Image.file(_proofImage!, fit: BoxFit.cover),
                          if (_uploadedUrl.isNotEmpty)
                            Positioned(top: 8, right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFF16a34a),
                                    borderRadius: BorderRadius.circular(9999)),
                                child: Text('✓ Uploaded', style: GoogleFonts.outfit(
                                    fontSize: 10, color: Colors.white,
                                    fontWeight: FontWeight.w600)))),
                        ])
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.upload_file_rounded,
                              size: 40, color: Color(0xFF4ade80)),
                          const SizedBox(height: 8),
                          Text('Tap to upload receipt photo',
                              style: GoogleFonts.outfit(color: Colors.grey[400])),
                          Text('Gallery or Camera',
                              style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600])),
                        ])),
          ),
          const SizedBox(height: 20),
        ],

        // Cash note
        if (_selectedMethod != null && _isCash)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF16a34a).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF16a34a).withOpacity(0.2))),
            child: Row(children: [
              const Icon(Icons.payments_rounded, color: Color(0xFF4ade80), size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Pay cash directly to the store owner. Tap Submit to confirm.',
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[300]))),
            ])),

        if (_selectedMethod != null)
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16a34a),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: _submitting
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text('Submit Payment', style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 15)))),
        const SizedBox(height: 24),
      ])),
    );
  }
}
