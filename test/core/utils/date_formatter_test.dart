import 'package:cis_crm/core/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('DateFormatter', () {
    group('relative', () {
      test('returns "Just now" for dates less than a minute ago', () {
        final now = DateTime.now();
        expect(DateFormatter.relative(now), 'Just now');
      });

      test('returns minutes ago for dates less than an hour ago', () {
        final date = DateTime.now().subtract(const Duration(minutes: 5));
        expect(DateFormatter.relative(date), '5m ago');
      });

      test('returns hours ago for dates less than a day ago', () {
        final date = DateTime.now().subtract(const Duration(hours: 2));
        expect(DateFormatter.relative(date), '2h ago');
      });

      test('returns "Yesterday" for yesterday', () {
        final now = DateTime.now();
        final yesterday = DateTime(now.year, now.month, now.day - 1, 12);
        expect(DateFormatter.relative(yesterday), 'Yesterday');
      });

      test('returns month and day for older same-year dates', () {
        final now = DateTime.now();
        // Use a date far enough in the past to not be yesterday.
        final date = DateTime(now.year, 1, 5);
        final result = DateFormatter.relative(date);
        expect(result, contains('Jan'));
        expect(result, contains('5'));
      });
    });

    group('dateOnly', () {
      test('formats date correctly', () {
        final date = DateTime(2026, 3, 12);
        expect(DateFormatter.dateOnly(date), 'Mar 12, 2026');
      });
    });

    group('dateTime', () {
      test('formats date and time correctly', () {
        final date = DateTime(2026, 3, 12, 15, 45);
        final result = DateFormatter.dateTime(date);
        expect(result, contains('Mar 12, 2026'));
        // Use intl to get the expected time format (may contain \u202F).
        final expectedTime = DateFormat.jm().format(date);
        expect(result, contains(expectedTime));
      });
    });

    group('timeOnly', () {
      test('formats time correctly', () {
        final date = DateTime(2026, 3, 12, 15, 45);
        final expected = DateFormat.jm().format(date);
        expect(DateFormatter.timeOnly(date), expected);
      });
    });

    group('dateRange', () {
      test('formats same-day range as times', () {
        final start = DateTime(2026, 3, 12, 15);
        final end = DateTime(2026, 3, 12, 16, 30);
        final result = DateFormatter.dateRange(start, end);
        final expectedStart = DateFormat.jm().format(start);
        final expectedEnd = DateFormat.jm().format(end);
        expect(result, contains(expectedStart));
        expect(result, contains(expectedEnd));
        expect(result, contains('-'));
      });

      test('formats different-day range as dates', () {
        final start = DateTime(2026, 3, 12);
        final end = DateTime(2026, 3, 13);
        final result = DateFormatter.dateRange(start, end);
        expect(result, contains('Mar 12'));
        expect(result, contains('Mar 13'));
      });
    });
  });
}
