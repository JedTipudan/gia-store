import 'package:intl/intl.dart';

String formatPeso(dynamic amount) {
  if (amount == null) return '₱0.00';
  final num value = amount is String ? double.tryParse(amount) ?? 0 : amount;
  return '₱${NumberFormat('#,##0.00').format(value)}';
}

String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'N/A';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('MMM d, yyyy').format(date);
  } catch (_) {
    return dateStr;
  }
}
