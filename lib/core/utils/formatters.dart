import 'package:intl/intl.dart';

class Fmt {
  Fmt._();

  static String currency(num amount) =>
      'GHC ${NumberFormat('#,##0.00').format(amount)}';

  static String date(DateTime dt) => DateFormat('EEE, d MMM yyyy').format(dt);

  static String time(DateTime dt) => DateFormat('h:mm a').format(dt);

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
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) {
      final p = parts[0];
      return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'BC';
  }

  static String statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'SEARCHING':
        return 'Searching';
      case 'ASSIGNED':
        return 'Assigned';
      case 'ACCEPTED':
        return 'Accepted';
      case 'EN_ROUTE':
        return 'En Route';
      case 'ON_THE_WAY':
        return 'On the Way';
      case 'ARRIVED':
        return 'Arrived';
      case 'COLLECTING':
        return 'Collecting';
      case 'COLLECTED':
        return 'Collected';
      case 'COMPLETED':
        return 'Completed';
      case 'UNASSIGNED':
        return 'Unassigned';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Safely converts a dynamic value (num or String) to double.
  /// Handles Prisma Decimal serialised as "30.00" strings.
  static double toDouble(dynamic value, [double fallback = 0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static String timePrefLabel(String? pref) {
    switch ((pref ?? '').toUpperCase()) {
      case 'MORNING':
        return 'Morning (7–11am)';
      case 'AFTERNOON':
        return 'Afternoon (12–4pm)';
      case 'EVENING':
        return 'Evening (4–7pm)';
      default:
        return pref ?? '';
    }
  }

  static String categoryLabel(String? category) {
    switch ((category ?? '').toUpperCase()) {
      case 'HOUSEHOLD':
        return 'Household';
      case 'PLASTIC':
        return 'Plastic';
      case 'GLASS':
        return 'Glass';
      case 'METAL':
        return 'Metal';
      case 'ORGANIC':
        return 'Organic';
      case 'CONSTRUCTION':
        return 'Construction';
      case 'EWASTE':
        return 'E-Waste';
      default:
        return category ?? 'General';
    }
  }

  static String binSizeLabel(String size) {
    switch (size.toUpperCase()) {
      case 'SMALL':
        return 'Small (≤120L)';
      case 'MEDIUM':
        return 'Medium (180L)';
      case 'LARGE':
        return 'Large (240L)';
      default:
        return size;
    }
  }

  static String paymentMethodLabel(String method) {
    switch (method.toUpperCase()) {
      case 'MTN_MOMO':
        return 'MTN MoMo';
      case 'VODAFONE_CASH':
        return 'Telecel Cash';
      case 'AIRTELTIGO':
        return 'AirtelTigo Money';
      case 'CASH':
        return 'Cash on Pickup';
      default:
        return method;
    }
  }

  /// Formats an ISO date string to "12 Jan 2026" style.
  static String shortDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
