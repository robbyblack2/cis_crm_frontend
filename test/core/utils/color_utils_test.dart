import 'dart:ui';

import 'package:cis_crm/core/utils/color_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseHexColor', () {
    test('parses 6-digit hex string with # prefix', () {
      expect(parseHexColor('#FF5733'), const Color(0xFFFF5733));
    });

    test('parses 6-digit hex string without # prefix', () {
      expect(parseHexColor('FF5733'), const Color(0xFFFF5733));
    });

    test('parses lowercase hex', () {
      expect(parseHexColor('#ff5733'), const Color(0xFFFF5733));
    });

    test('parses 8-digit hex with alpha', () {
      expect(parseHexColor('#80FF5733'), const Color(0x80FF5733));
    });

    test('parses raw integer string', () {
      expect(
        parseHexColor('4294924595'),
        Color(int.parse('4294924595')),
      );
    });

    test('returns fallback for empty string', () {
      expect(parseHexColor(''), const Color(0xFF9E9E9E));
    });

    test('returns fallback for invalid string', () {
      expect(parseHexColor('not-a-color'), const Color(0xFF9E9E9E));
    });

    test('accepts custom fallback color', () {
      expect(
        parseHexColor('bad', fallback: const Color(0xFF000000)),
        const Color(0xFF000000),
      );
    });
  });
}
