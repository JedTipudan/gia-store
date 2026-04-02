import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/dialogs.dart';

class PaymentPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String paymentId;
  final String paymentType; // 'paluwagan' or 'food'
  final VoidCallback onSuccess;

  const PaymentPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.paymentId,
    required this.paymentType,
    required this.onSuccess,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  List _methods = [];
  String? _selectedMethod;
  Map? _selectedMethodData;
  final _refCtrl = TextEditingController();
  File? _proofImage;
  String _uploadedUrl = '';
  bool _uploading = false;
  bool _submitting = false;
  bool _loadingMethods = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _primary = Color(0xFF22c55e);
  static const _bg = Color(0xFF0A1A0E);
  static const _card = Color(0xFF162018);
  static const _surface = Color(0xFF0F2414);

  bool get _isCash =>
      _selectedMethodData?['icon'] == 'cash' ||
      (_selectedMethod?.toLowerCase().contains('cash') ?? false);
  bool get _needsProof => _selectedMethod != null && !_isCash;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadMethods();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  Future<void> _loadMethods() async {
    final res = await ApiService.get('/paluwagan/payment-methods/active');
    if (res.statusCode == 200 && mounted) {
      setState(() { _methods = jsonDecode(res.body); _loadingMethods = false; });
      _animCtrl.forward();
    }
  }

  void _selectMethod(Map m) {
    setState(() {
      _selectedMethod = m['name'];
      _selectedMethodData = m;
      _proofImage = null;
      _uploadedUrl = '';
      _refCtrl.clear();
    });
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Upload Receipt', style: GoogleFonts.outfit(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _sourceBtn(Icons.photo_library_rounded,
                'Gallery', () => Navigator.pop(context, ImageSource.gallery))),
            const SizedBox(width: 12),
            Expanded(child: _sourceBtn(Icons.camera_alt_rounded,
                'Camera', () => Navigator.pop(context, ImageSource.camera))),
          ]),
          const SizedBox(height: 8),
        ]),
      )));
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source,
        imageQuality: 75, maxWidth: 800);
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
    } catch (_) {
      setState(() => _uploading = false);
      if (mounted) showSnack(context, 'Upload error', error: true);
    }
  }

  Future<void> _submit() async {
    if (_selectedMethod == null) {
      showSnack(context, 'Please select a payment method', error: true); return;
    }
    if (_needsProof && _uploadedUrl.isEmpty) {
      showSnack(context, 'Please upload your payment receipt photo', error: true); return;
    }
    setState(() => _submitting = true);

    http.Response res;
    if (widget.paymentType == 'paluwagan') {
      res = await ApiService.patch2(
          '/paluwagan/payments/${widget.paymentId}/submit-proof', {
        'proofImageUrl': _needsProof ? _uploadedUrl : '',
        'paymentMethod': _selectedMethod,
        'referenceNumber': _needsProof ? _refCtrl.text.trim() : '',
      });
    } else {
      res = await ApiService.patch2('/orders/${widget.paymentId}/pay', {
        'paymentMethod': _selectedMethod,
        'referenceNumber': _needsProof ? _refCtrl.text.trim() : '',
        'proofImageUrl': _needsProof ? _uploadedUrl : '',
      });
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.statusCode == 200) {
      Navigator.pop(context);
      widget.onSuccess();
    } else {
      showSnack(context, 'Failed to submit. Try again.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Payment', style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context)),
      ),
      body: _loadingMethods
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Payment summary card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF052e16), Color(0xFF14532d)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color: _primary.withOpacity(0.15),
                          blurRadius: 20, offset: const Offset(0, 6))]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(width: 40, height: 40,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.receipt_long_rounded,
                              color: Colors.white, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.title, style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                          Text(widget.subtitle, style: GoogleFonts.outfit(
                              fontSize: 12, color: Colors.white.withOpacity(0.7))),
                        ])),
                      ]),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Amount Due', style: GoogleFonts.outfit(
                            fontSize: 13, color: Colors.white.withOpacity(0.7))),
                        Text(widget.amount, style: GoogleFonts.outfit(
                            fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 28),

                  // Payment method section
                  Text('Choose Payment Method', style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[400])),
                  const SizedBox(height: 12),

                  if (_methods.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: _card,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text('No payment methods available. Contact admin.',
                            style: GoogleFonts.outfit(color: Colors.orange, fontSize: 13))),
                      ]))
                  else
                    ...List.generate(_methods.length, (i) {
                      final m = _methods[i];
                      final selected = _selectedMethod == m['name'];
                      final isCashMethod = m['icon'] == 'cash' ||
                          m['name'].toString().toLowerCase().contains('cash');
                      return GestureDetector(
                        onTap: () => _selectMethod(m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: selected ? _primary.withOpacity(0.12) : _card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: selected ? _primary : Colors.white.withOpacity(0.08),
                                width: selected ? 2 : 1)),
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: selected
                                    ? _primary.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12)),
                              child: Icon(
                                isCashMethod ? Icons.payments_rounded
                                    : m['icon'] == 'bank'
                                        ? Icons.account_balance_rounded
                                        : Icons.phone_android_rounded,
                                color: selected ? _primary : Colors.grey[500],
                                size: 24)),
                            const SizedBox(width: 14),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(m['name'] ?? '', style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold, fontSize: 15,
                                  color: selected ? Colors.white : Colors.grey[300])),
                              if ((m['accountNumber'] ?? '').toString().isNotEmpty &&
                                  m['accountNumber'] != 'N/A')
                                Text(m['accountNumber'], style: GoogleFonts.outfit(
                                    fontSize: 14, color: _primary,
                                    fontWeight: FontWeight.w600)),
                              if ((m['accountName'] ?? '').toString().isNotEmpty)
                                Text(m['accountName'], style: GoogleFonts.outfit(
                                    fontSize: 12, color: Colors.grey[500])),
                            ])),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: selected
                                  ? const Icon(Icons.check_circle_rounded,
                                      color: _primary, size: 24, key: ValueKey('check'))
                                  : Icon(Icons.radio_button_unchecked,
                                      color: Colors.grey[700], size: 24,
                                      key: const ValueKey('uncheck')),
                            ),
                          ]),
                        ),
                      );
                    }),

                  // Instructions
                  if (_selectedMethodData != null &&
                      (_selectedMethodData!['instructions'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.15))),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_selectedMethodData!['instructions'],
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: Colors.blue[300]))),
                      ])),
                    const SizedBox(height: 16),
                  ],

                  // GCash/Online: reference + photo
                  if (_needsProof) ...[
                    Text('Payment Details', style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[400])),
                    const SizedBox(height: 12),
                    // Reference number
                    Container(
                      decoration: BoxDecoration(color: _card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.08))),
                      child: TextField(
                        controller: _refCtrl,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'Reference / Transaction Number',
                          labelStyle: GoogleFonts.outfit(color: Colors.grey[500]),
                          prefixIcon: const Icon(Icons.tag_rounded,
                              color: _primary, size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _primary, width: 2)),
                          filled: true, fillColor: _card,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Receipt photo upload
                    Text('Upload Receipt Photo', style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[400])),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _uploading ? null : _pickImage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity, height: 180,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: _uploadedUrl.isNotEmpty
                                  ? _primary : Colors.white.withOpacity(0.1),
                              width: _uploadedUrl.isNotEmpty ? 2 : 1)),
                        clipBehavior: Clip.antiAlias,
                        child: _uploading
                            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const CircularProgressIndicator(color: _primary),
                                const SizedBox(height: 12),
                                Text('Uploading receipt...',
                                    style: GoogleFonts.outfit(color: Colors.grey[400])),
                              ])
                            : _proofImage != null
                                ? Stack(fit: StackFit.expand, children: [
                                    Image.file(_proofImage!, fit: BoxFit.cover),
                                    if (_uploadedUrl.isNotEmpty)
                                      Positioned(top: 10, right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                              color: _primary,
                                              borderRadius: BorderRadius.circular(9999)),
                                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                                            const Icon(Icons.check_rounded,
                                                color: Colors.white, size: 14),
                                            const SizedBox(width: 4),
                                            Text('Uploaded', style: GoogleFonts.outfit(
                                                fontSize: 11, color: Colors.white,
                                                fontWeight: FontWeight.w600)),
                                          ]))),
                                    // Retake button
                                    Positioned(bottom: 10, right: 10,
                                      child: GestureDetector(
                                        onTap: _pickImage,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(8)),
                                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                                            const Icon(Icons.refresh_rounded,
                                                color: Colors.white, size: 14),
                                            const SizedBox(width: 4),
                                            Text('Retake', style: GoogleFonts.outfit(
                                                fontSize: 11, color: Colors.white)),
                                          ])))),
                                  ])
                                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Container(
                                      width: 56, height: 56,
                                      decoration: BoxDecoration(
                                          color: _primary.withOpacity(0.1),
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.upload_file_rounded,
                                          size: 28, color: _primary)),
                                    const SizedBox(height: 10),
                                    Text('Tap to upload receipt',
                                        style: GoogleFonts.outfit(
                                            color: Colors.grey[300], fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text('Gallery or Camera',
                                        style: GoogleFonts.outfit(
                                            fontSize: 12, color: Colors.grey[600])),
                                  ]),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Cash confirmation
                  if (_selectedMethod != null && _isCash) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _primary.withOpacity(0.2))),
                      child: Row(children: [
                        Container(width: 40, height: 40,
                          decoration: BoxDecoration(
                              color: _primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.payments_rounded,
                              color: _primary, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Cash Payment', style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('Pay directly to the store owner. '
                              'Tap Submit to confirm your payment.',
                              style: GoogleFonts.outfit(
                                  fontSize: 12, color: Colors.grey[400])),
                        ])),
                      ])),
                    const SizedBox(height: 24),
                  ],

                  // Submit button
                  if (_selectedMethod != null)
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          shadowColor: _primary.withOpacity(0.4)),
                        child: _submitting
                            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2)),
                                const SizedBox(width: 12),
                                Text('Submitting...', style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                              ])
                            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.send_rounded, size: 20),
                                const SizedBox(width: 10),
                                Text('Submit Payment', style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                              ]),
                      ),
                    ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
    );
  }

  Widget _sourceBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primary.withOpacity(0.2))),
          child: Column(children: [
            Icon(icon, color: _primary, size: 28),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w600)),
          ])));
}
