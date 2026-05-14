/// Feature-flag / remote-config interface.
///
/// Ships with a no-op default impl that always returns the hardcoded
/// default values from [FeatureFlags]. Every flag has a default so the
/// app must work even when no remote config service is reachable.
///
/// Projects that opt into Firebase Remote Config / LaunchDarkly /
/// Statsig / etc. register their concrete impl in DI.
///
/// In dev flavors, projects expose a debug screen at `/debug/flags`
/// listing every known flag with toggle UI. Toggles are stored locally
/// in `SharedPreferences` and override remote values until cleared.
abstract interface class FeatureFlagService {
  bool boolValue(String name, {required bool defaultValue});

  String stringValue(String name, {required String defaultValue});

  int intValue(String name, {required int defaultValue});

  double doubleValue(String name, {required double defaultValue});

  /// Force a refresh from the remote source. No-op for the default impl.
  Future<void> refresh();
}

/// Canonical flag names + hardcoded defaults.
///
/// Treat this class as the single source of truth for "which flags exist"
/// and "what does the app do when remote config is unreachable."
abstract final class FeatureFlags {
  static const minAppVersion = 'min_app_version';
  static const String minAppVersionDefault = '0.0.0';

  // Add more flags here as the project grows.
}

/// Default no-op impl: always returns the supplied default value.
class NoopFeatureFlagService implements FeatureFlagService {
  const NoopFeatureFlagService();

  @override
  bool boolValue(String name, {required bool defaultValue}) => defaultValue;

  @override
  String stringValue(String name, {required String defaultValue}) =>
      defaultValue;

  @override
  int intValue(String name, {required int defaultValue}) => defaultValue;

  @override
  double doubleValue(String name, {required double defaultValue}) =>
      defaultValue;

  @override
  Future<void> refresh() async {}
}
