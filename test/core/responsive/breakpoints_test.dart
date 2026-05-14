import 'package:cis_crm/core/responsive/breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('windowSizeFor', () {
    test('returns compact for narrow widths', () {
      expect(windowSizeFor(320), WindowSize.compact);
      expect(windowSizeFor(599), WindowSize.compact);
    });

    test('returns medium for tablet widths', () {
      expect(windowSizeFor(600), WindowSize.medium);
      expect(windowSizeFor(839), WindowSize.medium);
    });

    test('returns expanded for desktop widths', () {
      expect(windowSizeFor(1200), WindowSize.expanded);
      expect(windowSizeFor(1920), WindowSize.expanded);
    });
  });
}
