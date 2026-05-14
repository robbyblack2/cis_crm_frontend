abstract interface class FeatureFlagService {
  bool boolValue(String name, {required bool defaultValue});
  String stringValue(String name, {required String defaultValue});
  int intValue(String name, {required int defaultValue});
  double doubleValue(String name, {required double defaultValue});
  Future<void> refresh();
}

abstract final class FeatureFlags {
  static const minAppVersion = 'min_app_version';
  static const String minAppVersionDefault = '0.0.0';
}

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
