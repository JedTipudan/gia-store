import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/dialogs.dart';

class CustomerPackages extends StatefulWidget {
  const CustomerPackages({super.key});
  @override
  State<CustomerPackages> createState() => _CustomerPackagesState();
}

class _CustomerPackagesState extends State<CustomerPackages> {
  List _packages = [];
  List _myApplications = [];
  bool _loading = true;
  String _userId = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _userId = await AuthService.getUserId();
    try {
      final res = await ApiService.get('/paluwagan/packages/active');
      final myRes = await ApiService.get('/paluwagan/members/user/$_userId');
      if (res.statusCode == 200) setState(() {
        _packages = jsonDecode(res.body);
        _myApplications = myRes.statusCode == 200 ? jsonDecode(myRes.body) : [];
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  String _getApplicationStatus(int packageId) {
    final app = _myApplications.where((m) => m['paluwaganPackage']?['id'] == packageId).toList();
    if (app.isEmpty) return 'NONE';
    return app.first['status'] ?? 'NONE';
  }

  void _apply(Map pkg) async {
    final status = _getApplicationStatus(pkg['id']);
    if (status == 'PENDING') { showSnack(context, 'You already applied for this package'); return; }
    if (status == 'ACTIVE') { showSnack(context, 'You are already enrolled in this package'); return; }

    final confirmed = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Apply for ${pkg['name']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Weekly payment: ${formatPeso(pkg['weeklyAmount'])}', style: GoogleFonts.outfit()),
          Text('Duration: ${pkg['durationWeeks']} weeks', style: GoogleFonts.outfit()),
          Text('Total: ${formatPeso((pkg['weeklyAmount'] ?? 0) * (pkg['durationWeeks'] ?? 0))}',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF4ade80))),
          const SizedBox(height: 8),
          Text('Your application will be reviewed by the admin.',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Apply Now', style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
        ],
      )) ?? false;

    if (!confirmed) return;

    final username = await AuthService.getUsername();
    final profileRes = await ApiService.get('/auth/profile/$username');
    String fullName = username;
    String phone = '';
    if (profileRes.statusCode == 200) {
      final profile = jsonDecode(profileRes.body);
      fullName = profile['fullName'] ?? username;
      phone = profile['phone'] ?? '';
    }

    final res = await ApiService.post('/paluwagan/members/apply', {
      'fullName': fullName, 'phone': phone,
      'paluwaganPackage': {'id': pkg['id']},
      'user': {'id': int.parse(_userId)},
    });

    if (!mounted) return;
    if (res.statusCode == 200 || res.statusCode == 201) {
      showSnack(context, 'Application submitted! Waiting for admin approval.');
      _load();
    } else {
      showSnack(context, 'Failed to apply. Please try again.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Text('Available Packages', style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Apply to join a paluwagan group',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[400])),
              const SizedBox(height: 16),
              if (_myApplications.isNotEmpty) ...[
                Text('My Applications', style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[400])),
                const SizedBox(height: 8),
                ..._myApplications.map((m) => _applicationCard(m)),
                const SizedBox(height: 16),
                Text('All Packages', style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[400])),
                const SizedBox(height: 8),
              ],
              ..._packages.map((pkg) => _packageCard(pkg)),
            ]),
          );
  }

  Widget _applicationCard(Map m) {
    final status = m['status'] ?? 'PENDING';
    final colors = {'PENDING': Colors.orange, 'ACTIVE': const Color(0xFF4ade80),
      'REJECTED': Colors.red, 'COMPLETED': Colors.blue};
    final color = colors[status] ?? Colors.grey;
    return Card(margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.2),
          child: Icon(status == 'ACTIVE' ? Icons.check_circle : status == 'PENDING'
              ? Icons.hourglass_empty : Icons.cancel, color: color, size: 20)),
        title: Text(m['paluwaganPackage']?['name'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        subtitle: Text('Applied: ${formatDate(m['appliedAt'])}', style: GoogleFonts.outfit(fontSize: 12)),
        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(9999)),
          child: Text(status, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: color))),
      ));
  }

  Widget _packageCard(Map pkg) {
    final status = _getApplicationStatus(pkg['id']);
    final total = (pkg['weeklyAmount'] ?? 0) * (pkg['durationWeeks'] ?? 0);
    final canApply = status == 'NONE' || status == 'REJECTED';

    return Card(margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(pkg['name'] ?? '', style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFF16a34a).withOpacity(0.2),
                borderRadius: BorderRadius.circular(9999)),
            child: Text('Active', style: GoogleFonts.outfit(fontSize: 10,
                fontWeight: FontWeight.w600, color: const Color(0xFF4ade80)))),
        ]),
        if ((pkg['description'] ?? '').toString().isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 4),
            child: Text(pkg['description'], style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400]))),
        const SizedBox(height: 12),
        Row(children: [
          _chip('${formatPeso(pkg['weeklyAmount'])}/week', Icons.payments_outlined, const Color(0xFF4ade80)),
          const SizedBox(width: 8),
          _chip('${pkg['durationWeeks']} weeks', Icons.calendar_today, Colors.blue[300]!),
        ]),
        const SizedBox(height: 8),
        Text('Total: ${formatPeso(total)}', style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF4ade80))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: canApply ? () => _apply(pkg) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canApply ? const Color(0xFF16a34a) : Colors.grey[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12)),
            child: Text(
              status == 'PENDING' ? '⏳ Pending Approval'
                  : status == 'ACTIVE' ? '✓ Enrolled'
                  : status == 'REJECTED' ? 'Re-apply'
                  : 'Apply Now',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          )),
      ])));
  }

  Widget _chip(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color), const SizedBox(width: 4),
      Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ]));
}
