import 'package:intl/intl.dart';

abstract final class DateFormatter {
  /// Returns a human-readable relative time string.
  ///
  /// "Just now", "5m ago", "2h ago", "Yesterday", "Mar 12"
  static String relative(DateTime date, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final diff = clock.difference(date);

    if (diff.isNegative) return DateFormat.MMMd().format(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';

    final yesterday = DateTime(clock.year, clock.month, clock.day - 1);
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }

    if (diff.inHours < 24) return '${diff.inHours}h ago';

    if (date.year == clock.year) return DateFormat.MMMd().format(date);
    return DateFormat.yMMMd().format(date);
  }

  /// "Mar 12, 2026"
  static String dateOnly(DateTime date) => DateFormat.yMMMd().format(date);

  /// "Mar 12, 2026 at 3:45 PM"
  static String dateTime(DateTime date) {
    final d = DateFormat.yMMMd().format(date);
    final t = DateFormat.jm().format(date);
    return '$d at $t';
  }

  /// "3:45 PM"
  static String timeOnly(DateTime date) => DateFormat.jm().format(date);

  /// Returns a formatted date range.
  ///
  /// Same-day: "3:00 PM - 4:30 PM"
  /// Different days: "Mar 12 - Mar 13"
  static String dateRange(DateTime start, DateTime end) {
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    if (sameDay) {
      final startTime = DateFormat.jm().format(start);
      final endTime = DateFormat.jm().format(end);
      return '$startTime - $endTime';
    }

    final startDate = DateFormat.MMMd().format(start);
    final endDate = DateFormat.MMMd().format(end);
    return '$startDate - $endDate';
  }
}
