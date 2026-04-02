import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo update;
  final VoidCallback onLater;

  const UpdateDialog({super.key, required this.update, required this.onLater});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _scale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _download() async {
    setState(() => _downloading = true);
    await UpdateService.openDownload(widget.update.downloadUrl);
    if (mounted) setState(() => _downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1A10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF16a34a).withOpacity(0.4)),
              boxShadow: [
                BoxShadow(color: const Color(0xFF16a34a).withOpacity(0.2),
                    blurRadius: 40, spreadRadius: 0),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Header gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF052e16), Color(0xFF16a34a)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: Column(children: [
                  // Animated icon
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2)),
                    child: const Icon(Icons.system_update_rounded,
                        color: Colors.white, size: 32)),
                  const SizedBox(height: 12),
                  Text('New Update Available! 🎉',
                      style: GoogleFonts.outfit(fontSize: 18,
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(9999)),
                      child: Text('v${widget.update.currentVersion}',
                          style: GoogleFonts.outfit(fontSize: 12,
                              color: Colors.white.withOpacity(0.7)))),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(9999)),
                      child: Text('v${widget.update.version}',
                          style: GoogleFonts.outfit(fontSize: 12,
                              fontWeight: FontWeight.bold, color: Colors.white))),
                  ]),
                ]),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (widget.update.releaseNotes.isNotEmpty) ...[
                    Text("What's New", style: GoogleFonts.outfit(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: Colors.grey[400])),
                    const SizedBox(height: 10),
                    ...widget.update.releaseNotes.map((note) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: Color(0xFF22c55e), shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(note, style: GoogleFonts.outfit(
                            fontSize: 13, color: Colors.grey[300]))),
                      ]),
                    )),
                    const SizedBox(height: 16),
                  ],

                  // Download button
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: _downloading ? null : _download,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16a34a),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _downloading
                          ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2)),
                              const SizedBox(width: 10),
                              Text('Opening...', style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                            ])
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.download_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text('Download Update',
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold, fontSize: 15)),
                            ]),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Later button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: widget.onLater,
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: Text('Remind me later',
                          style: GoogleFonts.outfit(
                              color: Colors.grey[500], fontSize: 13)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// Helper function to show the update dialog
void showUpdateDialog(BuildContext context, UpdateInfo update,
    {VoidCallback? onLater}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (_) => UpdateDialog(
      update: update,
      onLater: () {
        Navigator.pop(context);
        onLater?.call();
      },
    ),
  );
}
