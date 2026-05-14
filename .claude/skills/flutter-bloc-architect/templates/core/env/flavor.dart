/// Flavor identifier — a Dart-side enum that drives per-environment config.
///
/// Path A: native flavors (gradle product flavors, iOS schemes per flavor)
/// are NOT used by default. The flavor is selected at compile time via
/// `--dart-define=FLAVOR=<name>` with `defaultValue: 'prod'`, so bare
/// `flutter run` and `flutter run --release` always run prod, on every
/// platform (Android, iOS, web, macOS, Windows, Linux).
///
/// To resolve a name into the actual configuration, use
/// [FlavorConfig.byName] from `flavor_config.dart`.
enum Flavor { dev, prod }

extension FlavorParse on Flavor {
  static Flavor fromName(String name) {
    return Flavor.values.firstWhere(
      (f) => f.name == name,
      orElse: () => Flavor.prod,
    );
  }
}
