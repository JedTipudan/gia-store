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

class CustomerPayments extends StatefulWidget {
  final String userId;
  final int? memberId;
  const CustomerPayments({super.key, required this.userId, this.memberId});
  @override
  State<CustomerPayments> createState() => _CustomerPaymentsState();
}

class _CustomerPaymentsState extends State<CustomerPayments> {
  List _payments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (widget.userId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final path = widget.memberId != null
          ? '/paluwagan/payments/member/${widget.memberId}'
          : '/paluwagan/payments/user/${widget.userId}';
      final res = await ApiService.get(path);
      if (res.statusCode == 200) {
        setState(() { _payments = jsonDecode(res.body); _loading = false; });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  void _submitPayment(Map payment) async {
    List methods = [];
    final methodRes = await ApiService.get('/paluwagan/payment-methods/active');
    if (methodRes.statusCode == 200) methods = jsonDecode(methodRes.body);
    if (!mounted) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PaymentProofForm(
        payment: payment, methods: methods,
        onSubmitted: () {
          _load();
          if (mounted) showSnack(context, 'Payment submitted! Waiting for admin approval.');
        }),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'APPROVED': return const Color(0xFF4ade80);
      case 'SUBMITTED': return Colors.orange;
      case 'REJECTED': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_payments.isEmpty) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[700]),
        const SizedBox(height: 12),
        Text('No payments yet', style: GoogleFonts.outfit(color: Colors.grey[500])),
        const SizedBox(height: 8),
        Text('Apply for a package first',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
      ]));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        itemBuilder: (_, i) {
          final p = _payments[i];
          final isPaid = p['paid'] == true;
          final approvalStatus = p['approvalStatus'] ?? 'PENDING';
          final canSubmit = !isPaid && approvalStatus != 'SUBMITTED';
          final statusColor = _statusColor(isPaid ? 'APPROVED' : approvalStatus);

          return Card(margin: const EdgeInsets.only(bottom: 10),
            child: Padding(padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(p['periodLabel'] ?? 'Week ${p['periodNumber']}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(9999)),
                    child: Text(isPaid ? 'Paid ✓' : approvalStatus,
                        style: GoogleFonts.outfit(fontSize: 11,
                            fontWeight: FontWeight.w600, color: statusColor))),
                ]),
                const SizedBox(height: 4),
                Text('Due: ${formatDate(p['dueDate'])}',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400])),
                if ((p['paymentMethod'] ?? '').toString().isNotEmpty)
                  Text('Method: ${p['paymentMethod']}',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400])),
                if ((p['referenceNumber'] ?? '').toString().isNotEmpty)
                  Text('Ref: ${p['referenceNumber']}',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400])),
                if ((p['adminNote'] ?? '').toString().isNotEmpty)
                  Container(margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('Admin note: ${p['adminNote']}',
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.redAccent))),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(formatPeso(p['amount']), style: GoogleFonts.outfit(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: const Color(0xFF4ade80))),
                  if (canSubmit)
                    ElevatedButton.icon(
                      onPressed: () => _submitPayment(p),
                      icon: const Icon(Icons.upload_rounded, size: 16),
                      label: Text('Submit Payment',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16a34a),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8)))
                  else if (approvalStatus == 'SUBMITTED')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('Awaiting approval',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange))),
                ]),
              ])));
        }),
    );
  }
}

// ─── Payment Proof Form ───────────────────────────────────────────────────────

class _PaymentProofForm extends StatefulWidget {
  final Map payment;
  final List methods;
  final VoidCallback onSubmitted;
  const _PaymentProofForm({
    required this.payment, required this.methods, required this.onSubmitted});
  @override
  State<_PaymentProofForm> createState() => _PaymentProofFormState();
}

class _PaymentProofFormState extends State<_PaymentProofForm> {
  String? _selectedMethod;
  Map? _selectedMethodData;
  final _refCtrl = TextEditingController();
  File? _proofImage;
  String _uploadedUrl = '';
  bool _uploading = false;
  bool _submitting = false;

  // Cash = no reference or photo needed
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
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
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
        // Handle
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Submit Payment', style: GoogleFonts.outfit(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          IconButton(icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
        ]),
        Text('${widget.payment['periodLabel'] ?? 'Week ${widget.payment['periodNumber']}'} — ${formatPeso(widget.payment['amount'])}',
            style: GoogleFonts.outfit(color: Colors.grey[400])),
        const SizedBox(height: 20),

        // Payment method selector
        Align(alignment: Alignment.centerLeft,
          child: Text('Select Payment Method',
              style: GoogleFonts.outfit(fontSize: 13,
                  fontWeight: FontWeight.w600, color: Colors.grey[400]))),
        const SizedBox(height: 10),
        ...widget.methods.map((m) {
          final selected = _selectedMethod == m['name'];
          return GestureDetector(
            onTap: () => setState(() {
              _selectedMethod = m['name'];
              _selectedMethodData = m;
              // Reset all proof fields when switching methods
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
            (_selectedMethodData!['instructions'] ?? '').toString().isNotEmpty) ...[
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
        ],

        // Online payment: show reference + photo
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
            child: Text('Upload Payment Receipt *',
                style: GoogleFonts.outfit(fontSize: 13,
                    fontWeight: FontWeight.w600, color: Colors.grey[400]))),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _uploading ? null : _pickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity, height: 160,
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
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
                              style: GoogleFonts.outfit(
                                  fontSize: 11, color: Colors.grey[600])),
                        ])),
          ),
          const SizedBox(height: 20),
        ],

        // Cash: just a note
        if (_selectedMethod != null && _isCash) ...[
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
        ],

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
