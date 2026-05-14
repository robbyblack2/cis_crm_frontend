/// Cross-cutting analytics interface.
///
/// Ships with a no-op default impl. Projects that enable analytics
/// (`firebase_analytics`, `mixpanel_flutter`, `amplitude_flutter`, etc.)
/// register their concrete impl in DI:
///
/// ```dart
/// getIt.registerLazySingleton<AnalyticsService>(
///   () => FirebaseAnalyticsService(...),
/// );
/// ```
///
/// Events fire from `BlocListener` widgets at the App or page level, never
/// from inside bloc handlers. Keeps blocs unit-testable and decoupled.
///
/// PII rule: never pass emails, names, or other identifying data through
/// these methods. Pass IDs and enums. The contract is documented, not
/// auto-verified.
abstract interface class AnalyticsService {
  Future<void> identify(String userId, [Map<String, Object?>? traits]);

  Future<void> track(String event, [Map<String, Object?>? properties]);

  Future<void> screen(String name, [Map<String, Object?>? properties]);

  Future<void> reset();
}

/// Default no-op impl. Registered in DI when the project does not opt
/// into analytics — keeps `getIt<AnalyticsService>()` always-callable.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> identify(String userId, [Map<String, Object?>? traits]) async {}

  @override
  Future<void> track(String event, [Map<String, Object?>? properties]) async {}

  @override
  Future<void> screen(String name, [Map<String, Object?>? properties]) async {}

  @override
  Future<void> reset() async {}
}
