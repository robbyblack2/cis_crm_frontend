abstract interface class AnalyticsService {
  Future<void> identify(String userId, [Map<String, Object?>? traits]);
  Future<void> track(String event, [Map<String, Object?>? properties]);
  Future<void> screen(String name, [Map<String, Object?>? properties]);
  Future<void> reset();
}

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
