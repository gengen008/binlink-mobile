import 'package:intl/intl.dart';

class Fmt {
  Fmt._();

  static String currency(num amount) =>
      'GHC ${NumberFormat('#,##0.00').format(amount)}';

  static String date(DateTime dt) =>
      DateFormat('EEE, d MMM yyyy').format(dt);

  static String time(DateTime dt) =>
      DateFormat('h:mm a').format(dt);

  static String dateTime(DateTime dt) =>
      DateFormat('d MMM • h:mm a').format(dt);

  static String relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static String initials(String? name) {
    if (name == null || name.trim().isEmpty) return 'BC';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final n = name.trim();
    return n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase();
  }

  static String statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':   return 'Pending';
      case 'ACCEPTED':  return 'Accepted';
      case 'EN_ROUTE':  return 'En Route';
      case 'ARRIVED':   return 'Arrived';
      case 'COMPLETED': return 'Completed';
      case 'CANCELLED': return 'Cancelled';
      default:          return status;
    }
  }

  static String binSizeLabel(String size) {
    switch (size.toUpperCase()) {
      case 'SMALL':  return 'Small (≤120L)';
      case 'MEDIUM': return 'Medium (180L)';
      case 'LARGE':  return 'Large (240L)';
      default:       return size;
    }
  }

  static String paymentMethodLabel(String method) {
    switch (method.toUpperCase()) {
      case 'MTN_MOMO':       return 'MTN MoMo';
      case 'VODAFONE_CASH':  return 'Telecel Cash';
      case 'AIRTELTIGO':     return 'AirtelTigo Money';
      case 'CASH':           return 'Cash on Pickup';
      default:               return method;
    }
  }

  /// Formats an ISO date string to "12 Jan 2026" style.
  static String shortDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
