import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/food_image.dart';

class CustomerFoodMenu extends StatefulWidget {
  const CustomerFoodMenu({super.key});
  @override
  State<CustomerFoodMenu> createState() => _CustomerFoodMenuState();
}

class _CustomerFoodMenuState extends State<CustomerFoodMenu> {
  List _items = [];
  bool _loading = true;
  String _selectedCategory = 'All';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _load();
    SharedPreferences.getInstance().then((p) =>
        setState(() => _userId = p.getString('userId') ?? ''));
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/food-items/today');
      if (res.statusCode == 200) {
        setState(() { _items = jsonDecode(res.body); _loading = false; });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  List<String> get _categories {
    final cats = _items
        .map((i) => (i['category'] ?? '').toString())
        .where((c) => c.isNotEmpty).toSet().toList();
    return ['All', ...cats];
  }

  List get _filtered => _selectedCategory == 'All'
      ? _items
      : _items.where((i) => i['category'] == _selectedCategory).toList();

  void _orderItem(Map item) async {
    if (_userId.isEmpty) {
      showSnack(context, 'Please login again', error: true); return;
    }

    // Step 1: Confirm order
    final confirmed = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(item['name'] ?? '',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          FoodImage(imageUrl: item['imageUrl'], height: 140, width: double.infinity),
          const SizedBox(height: 12),
          if ((item['description'] ?? '').toString().isNotEmpty)
            Text(item['description'], style: GoogleFonts.outfit(
                fontSize: 13, color: Colors.grey[400])),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Price', style: GoogleFonts.outfit(color: Colors.grey[400])),
            Text(formatPeso(item['price']), style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: const Color(0xFF4ade80), fontSize: 18)),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Order Now', style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
        ],
      )) ?? false;

    if (!confirmed || !mounted) return;

    // Step 2: Place order
    final res = await ApiService.post('/orders', {
      'userId': int.parse(_userId),
      'foodItemId': item['id'],
      'quantity': 1,
    });

    if (!mounted) return;
    if (res.statusCode != 200 && res.statusCode != 201) {
      showSnack(context, 'Failed to place order', error: true); return;
    }

    final order = jsonDecode(res.body);

    // Step 3: Show payment methods
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PaymentSheet(
        order: order,
        item: item,
        onPaid: () {
          if (mounted) showSnack(context, '✓ Payment submitted! Check History tab.');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_items.isEmpty) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.restaurant_menu_outlined, size: 72, color: Colors.grey[700]),
        const SizedBox(height: 16),
        Text("No food available today", style: GoogleFonts.outfit(
            fontSize: 16, color: Colors.grey[400])),
        const SizedBox(height: 8),
        Text('Check back later!', style: GoogleFonts.outfit(
            fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 16),
        TextButton.icon(onPressed: _load,
          icon: const Icon(Icons.refresh, color: Color(0xFF4ade80)),
          label: Text('Refresh', style: GoogleFonts.outfit(
              color: const Color(0xFF4ade80)))),
      ],
    ));

    return RefreshIndicator(
      onRefresh: _load,
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            const Icon(Icons.wb_sunny_rounded, color: Color(0xFF4ade80), size: 18),
            const SizedBox(width: 8),
            Text("Today's Menu", style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
            const Spacer(),
            Text('${_filtered.length} items', style: GoogleFonts.outfit(
                fontSize: 12, color: Colors.grey[400])),
          ]),
        ),
        // Category chips
        if (_categories.length > 1)
          SizedBox(height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF16a34a) : const Color(0xFF1A2E1E),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: selected
                          ? const Color(0xFF16a34a) : Colors.grey[700]!)),
                    child: Text(cat, style: GoogleFonts.outfit(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.grey[400])),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        // Grid
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12,
              mainAxisSpacing: 12, childAspectRatio: 0.72),
          itemCount: _filtered.length,
          itemBuilder: (_, i) {
            final item = _filtered[i];
            return GestureDetector(
              onTap: () => _orderItem(item),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2E1E),
                  borderRadius: BorderRadius.circular(14)),
                clipBehavior: Clip.antiAlias,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Stack(children: [
                    FoodImage(imageUrl: item['imageUrl'],
                        height: 120, width: double.infinity,
                        placeholder: Container(height: 120,
                            color: const Color(0xFF0F2414),
                            child: Center(child: Icon(Icons.fastfood_rounded,
                                size: 44, color: Colors.grey[700])))),
                    Positioned(bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.black54,
                        child: Center(child: Text('Tap to Order',
                            style: GoogleFonts.outfit(fontSize: 10,
                                color: Colors.white, fontWeight: FontWeight.w600))))),
                  ]),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item['name'] ?? '', style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        if ((item['category'] ?? '').toString().isNotEmpty)
                          Text(item['category'], style: GoogleFonts.outfit(
                              fontSize: 10, color: Colors.grey[500]), maxLines: 1),
                        if ((item['description'] ?? '').toString().isNotEmpty)
                          Text(item['description'], style: GoogleFonts.outfit(
                              fontSize: 10, color: Colors.grey[600]),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                      ]),
                      Text(formatPeso(item['price']), style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4ade80), fontSize: 15)),
                    ]),
                  )),
                ]),
              ),
            );
          },
        )),
      ]),
    );
  }
}

// ─── Payment Sheet ────────────────────────────────────────────────────────────

class _PaymentSheet extends StatefulWidget {
  final Map order;
  final Map item;
  final VoidCallback onPaid;
  const _PaymentSheet({required this.order, required this.item, required this.onPaid});
  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  List _methods = [];
  String? _selectedMethod;
  Map? _selectedMethodData;
  final _refCtrl = TextEditingController();
  File? _proofImage;
  String _uploadedUrl = '';
  bool _uploading = false;
  bool _submitting = false;

  // Cash = no reference/photo needed, online = required
  bool get _isCash => _selectedMethodData?['icon'] == 'cash' ||
      (_selectedMethod?.toLowerCase().contains('cash') ?? false);
  bool get _needsProof => !_isCash;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    final res = await ApiService.get('/paluwagan/payment-methods/active');
    if (res.statusCode == 200 && mounted) {
      setState(() => _methods = jsonDecode(res.body));
    }
  }

  Future<void> _pickProof() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF0F2414),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        ListTile(leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF4ade80)),
            title: Text('Choose from Gallery', style: GoogleFonts.outfit(color: Colors.white)),
            onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ListTile(leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF4ade80)),
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
    } catch (_) {
      setState(() => _uploading = false);
      if (mounted) showSnack(context, 'Upload error', error: true);
    }
  }

  Future<void> _submit() async {
    if (_selectedMethod == null) {
      showSnack(context, 'Please select a payment method', error: true); return;
    }
    // Only require proof for non-cash payments
    if (_needsProof && _uploadedUrl.isEmpty) {
      showSnack(context, 'Please upload your payment receipt photo', error: true); return;
    }
    setState(() => _submitting = true);
    final res = await ApiService.patch2('/orders/${widget.order['id']}/pay', {
      'paymentMethod': _selectedMethod,
      'referenceNumber': _needsProof ? _refCtrl.text.trim() : '',
      'proofImageUrl': _needsProof ? _uploadedUrl : '',
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.statusCode == 200) {
      Navigator.pop(context);
      widget.onPaid();
    } else {
      showSnack(context, 'Failed to submit payment', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          // Header
          Row(children: [
            Container(width: 48, height: 48,
              decoration: BoxDecoration(color: const Color(0xFF16a34a).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.receipt_long_rounded,
                  color: Color(0xFF4ade80), size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pay for Order', style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('${widget.item['name']} • ${formatPeso(widget.order['totalPrice'])}',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[400])),
            ])),
          ]),
          const SizedBox(height: 20),

          // Payment methods
          if (_methods.isEmpty)
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('No payment methods set up yet. Contact the store.',
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.orange))),
              ]))
          else ...[
            Align(alignment: Alignment.centerLeft,
              child: Text('Select Payment Method',
                  style: GoogleFonts.outfit(fontSize: 13,
                      fontWeight: FontWeight.w600, color: Colors.grey[400]))),
            const SizedBox(height: 10),
            ..._methods.map((m) {
              final selected = _selectedMethod == m['name'];
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedMethod = m['name'];
                  _selectedMethodData = m;
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

            // Reference number - only for online payments
            if (_needsProof) ...[
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
                      borderSide: const BorderSide(color: Color(0xFF4ade80), width: 2)),
                ),
              ),
              const SizedBox(height: 14),

              // Proof upload
              Align(alignment: Alignment.centerLeft,
                child: Text('Upload Payment Receipt *',
                    style: GoogleFonts.outfit(fontSize: 13,
                        fontWeight: FontWeight.w600, color: Colors.grey[400]))),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _uploading ? null : _pickProof,
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
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF16a34a),
                                        borderRadius: BorderRadius.circular(9999)),
                                    child: Text('✓ Uploaded', style: GoogleFonts.outfit(
                                        fontSize: 10, color: Colors.white,
                                        fontWeight: FontWeight.w600)))),
                            ])
                          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.upload_file_rounded,
                                  size: 44, color: Color(0xFF4ade80)),
                              const SizedBox(height: 8),
                              Text('Tap to upload receipt photo',
                                  style: GoogleFonts.outfit(color: Colors.grey[400])),
                              Text('Gallery or Camera',
                                  style: GoogleFonts.outfit(
                                      fontSize: 11, color: Colors.grey[600])),
                            ]),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              // Cash - just a note
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF16a34a).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF16a34a).withOpacity(0.2))),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: Color(0xFF4ade80), size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Pay cash directly to the store. Tap Submit to confirm your order.',
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[300]))),
                ]),
              ),
            ],

            // Submit button
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16a34a),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Text('Submit Payment',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 16)),
              )),
            const SizedBox(height: 24),
          ],
        ]),
      ),
    );
  }
}
