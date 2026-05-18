import 'package:cis_crm/core/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  // Fixed clock so tests are deterministic regardless of wall time.
  final now = DateTime(2026, 6, 15, 14, 30); // Jun 15 2026, 2:30 PM

  group('DateFormatter', () {
    group('relative', () {
      test('returns "Just now" for dates less than a minute ago', () {
        final date = now.subtract(const Duration(seconds: 30));
        expect(DateFormatter.relative(date, now: now), 'Just now');
      });

      test('returns minutes ago for dates less than an hour ago', () {
        final date = now.subtract(const Duration(minutes: 5));
        expect(DateFormatter.relative(date, now: now), '5m ago');
      });

      test('returns hours ago for dates less than a day ago (same day)', () {
        final date = now.subtract(const Duration(hours: 2));
        expect(DateFormatter.relative(date, now: now), '2h ago');
      });

      test('returns "Yesterday" for yesterday even if < 24 h ago', () {
        // Yesterday at noon — only 26.5 h before `now`, but calendar-yesterday.
        final yesterday = DateTime(2026, 6, 14, 12);
        expect(DateFormatter.relative(yesterday, now: now), 'Yesterday');
      });

      test('returns "Yesterday" for yesterday at midnight', () {
        final yesterday = DateTime(2026, 6, 14);
        expect(DateFormatter.relative(yesterday, now: now), 'Yesterday');
      });

      test('returns hours ago for earlier today even if > 12 h ago', () {
        // 14.5 hours ago but still the same calendar day.
        final earlyToday = DateTime(2026, 6, 15);
        expect(DateFormatter.relative(earlyToday, now: now), '14h ago');
      });

      test('returns month and day for older same-year dates', () {
        final date = DateTime(2026, 1, 5);
        final result = DateFormatter.relative(date, now: now);
        expect(result, contains('Jan'));
        expect(result, contains('5'));
      });

      test('returns full date for previous-year dates', () {
        final date = DateTime(2025, 3, 10);
        final result = DateFormatter.relative(date, now: now);
        expect(result, contains('2025'));
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
