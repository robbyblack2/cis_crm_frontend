import 'package:cis_crm/core/env/flavor.dart';
import 'package:logger/logger.dart';

class FlavorConfig {
  const FlavorConfig({
    required this.flavor,
    required this.flavorName,
    required this.apiBaseUrl,
    required this.logLevel,
    this.sentryDsn,
    this.sentryTracesSampleRate = 0,
  });

  factory FlavorConfig.byName(String name) {
    return switch (name) {
      'dev' => const FlavorConfig(
          flavor: Flavor.dev,
          flavorName: 'dev',
          apiBaseUrl: 'http://localhost:8087',
          logLevel: Level.trace,
          sentryTracesSampleRate: 1,
        ),
      _ => const FlavorConfig(
          flavor: Flavor.prod,
          flavorName: 'prod',
          apiBaseUrl: 'http://localhost:8087',
          logLevel: Level.warning,
          sentryTracesSampleRate: 0.1,
        ),
    };
  }

  final Flavor flavor;
  final String flavorName;
  final String apiBaseUrl;
  final Level logLevel;
  final String? sentryDsn;
  final double sentryTracesSampleRate;

  bool get isDev => flavor == Flavor.dev;
  bool get isProd => flavor == Flavor.prod;
}
