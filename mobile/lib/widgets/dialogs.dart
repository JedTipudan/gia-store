import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<bool> confirmDelete(BuildContext context, String itemName) async {
  return await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
        const SizedBox(width: 8),
        Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ]),
      content: Text('Are you sure you want to delete "$itemName"?\nThis cannot be undone.',
          style: GoogleFonts.outfit(fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  ) ?? false;
}

void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: GoogleFonts.outfit()),
    backgroundColor: error ? Colors.red : const Color(0xFF16a34a),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}
