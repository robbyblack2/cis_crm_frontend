import 'package:cis_crm/core/utils/file_size_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileSizeFormatter', () {
    test('formats bytes', () {
      expect(FileSizeFormatter.format(456), '456 B');
    });

    test('formats zero bytes', () {
      expect(FileSizeFormatter.format(0), '0 B');
    });

    test('formats negative bytes as 0 B', () {
      expect(FileSizeFormatter.format(-100), '0 B');
    });

    test('formats kilobytes', () {
      expect(FileSizeFormatter.format(1229), '1.2 KB');
    });

    test('formats megabytes', () {
      expect(FileSizeFormatter.format(3670016), '3.5 MB');
    });

    test('formats gigabytes', () {
      expect(FileSizeFormatter.format(1073741824), '1.0 GB');
    });

    test('formats exact kilobyte', () {
      expect(FileSizeFormatter.format(1024), '1.0 KB');
    });

    test('formats 1023 bytes as bytes', () {
      expect(FileSizeFormatter.format(1023), '1023 B');
    });
  });
}
