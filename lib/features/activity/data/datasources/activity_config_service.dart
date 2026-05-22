import 'package:cis_crm/app/injection.dart';
import 'package:dio/dio.dart';

/// Fetches activity statuses and subtypes from the API.
/// Caches results in memory to avoid repeated calls.
class ActivityConfigService {
  ActivityConfigService._();
  static final instance = ActivityConfigService._();

  final Map<String, List<ActivityStatus>> _statusCache = {};
  final Map<String, List<ActivitySubtype>> _subtypeCache = {};

  Future<List<ActivityStatus>> getStatuses(String activityType) async {
    if (_statusCache.containsKey(activityType)) {
      return _statusCache[activityType]!;
    }
    try {
      final response = await getIt<Dio>().get<Map<String, dynamic>>(
        '/api/activity-statuses',
        queryParameters: {'activity_type': activityType},
      );
      final list = response.data?['data'] as List<dynamic>? ?? [];
      final statuses = list
          .cast<Map<String, dynamic>>()
          .map((j) => ActivityStatus(
                id: j['id'] as String? ?? '',
                name: j['name'] as String? ?? '',
                phase: j['phase'] as String? ?? 'open',
                isDefault: j['is_default'] as bool? ?? false,
              ))
          .toList();
      _statusCache[activityType] = statuses;
      return statuses;
    } catch (_) {
      return [];
    }
  }

  Future<List<ActivitySubtype>> getSubtypes(String activityType) async {
    if (_subtypeCache.containsKey(activityType)) {
      return _subtypeCache[activityType]!;
    }
    try {
      final response = await getIt<Dio>().get<Map<String, dynamic>>(
        '/api/activity-subtypes',
        queryParameters: {'activity_type': activityType},
      );
      final list = response.data?['data'] as List<dynamic>? ?? [];
      final subtypes = list
          .cast<Map<String, dynamic>>()
          .map((j) => ActivitySubtype(
                id: j['id'] as String? ?? '',
                name: j['name'] as String? ?? '',
              ))
          .toList();
      _subtypeCache[activityType] = subtypes;
      return subtypes;
    } catch (_) {
      return [];
    }
  }

  /// Returns the default status for a given activity type.
  Future<ActivityStatus?> getDefaultStatus(String activityType) async {
    final statuses = await getStatuses(activityType);
    return statuses.cast<ActivityStatus?>().firstWhere(
          (s) => s!.isDefault,
          orElse: () => statuses.isNotEmpty ? statuses.first : null,
        );
  }

  /// Returns the first closed-phase status (for "mark as complete").
  Future<ActivityStatus?> getClosedStatus(String activityType) async {
    final statuses = await getStatuses(activityType);
    return statuses.cast<ActivityStatus?>().firstWhere(
          (s) => s!.phase == 'closed',
          orElse: () => null,
        );
  }

  void clearCache() {
    _statusCache.clear();
    _subtypeCache.clear();
  }
}

class ActivityStatus {
  const ActivityStatus({
    required this.id,
    required this.name,
    required this.phase,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String phase;
  final bool isDefault;
}

class ActivitySubtype {
  const ActivitySubtype({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}
