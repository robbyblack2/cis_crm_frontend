import 'package:logger/logger.dart';

import 'flavor.dart';

/// Per-flavor configuration record.
///
/// Public values (base URL, log level, sample rates) are hardcoded per
/// flavor in this file. Secrets (Sentry DSN, third-party API keys) come
/// in via additional `--dart-define=...` values at build time and are
/// passed into [FlavorConfig.byName] from `main.dart`.
///
/// `byName` is the single entry point that converts a flavor string from
/// `--dart-define=FLAVOR=...` into the resolved configuration.
class FlavorConfig {
  const FlavorConfig({
    required this.flavor,
    required this.flavorName,
    required this.apiBaseUrl,
    required this.logLevel,
    this.sentryDsn,
    this.sentryTracesSampleRate = 0.0,
  });

  final Flavor flavor;
  final String flavorName;
  final String apiBaseUrl;
  final Level logLevel;

  /// When non-null, [main.dart] wraps `runApp` in `SentryFlutter.init` and
  /// the bloc observer / global error handlers forward to Sentry.
  final String? sentryDsn;
  final double sentryTracesSampleRate;

  /// Resolves a flavor name (typically from `--dart-define=FLAVOR=...`)
  /// into a [FlavorConfig]. Defaults to prod when the name is missing or
  /// unknown — keeps bare `flutter run` and `flutter run --release` working.
  factory FlavorConfig.byName(String name) {
    return switch (name) {
      'dev' => const FlavorConfig(
          flavor: Flavor.dev,
          flavorName: 'dev',
          apiBaseUrl: 'https://api.dev.example.com',
          logLevel: Level.trace,
          sentryTracesSampleRate: 1.0,
        ),
      _ => const FlavorConfig(
          flavor: Flavor.prod,
          flavorName: 'prod',
          apiBaseUrl: 'https://api.example.com',
          logLevel: Level.warning,
          sentryTracesSampleRate: 0.1,
        ),
    };
  }

  bool get isDev => flavor == Flavor.dev;
  bool get isProd => flavor == Flavor.prod;
}
