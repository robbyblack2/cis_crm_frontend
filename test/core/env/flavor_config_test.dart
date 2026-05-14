import 'package:cis_crm/core/env/flavor.dart';
import 'package:cis_crm/core/env/flavor_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  group('FlavorConfig', () {
    test('byName dev returns dev config', () {
      final config = FlavorConfig.byName('dev');
      expect(config.flavor, Flavor.dev);
      expect(config.isDev, isTrue);
      expect(config.logLevel, Level.trace);
    });

    test('byName prod returns prod config', () {
      final config = FlavorConfig.byName('prod');
      expect(config.flavor, Flavor.prod);
      expect(config.isProd, isTrue);
      expect(config.logLevel, Level.warning);
    });

    test('byName unknown defaults to prod', () {
      final config = FlavorConfig.byName('unknown');
      expect(config.isProd, isTrue);
    });
  });
}
