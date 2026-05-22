import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/activity/data/models/activity_model.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:dio/dio.dart';

class ActivitiesDataSource {
  const ActivitiesDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Fetch activities with full filter support matching the backend API.
  Future<List<ActivityModel>> getActivities({
    ActivityType? type,
    String? phase,
    String? statusId,
    String? assigneeId,
    String? entityType,
    String? entityId,
    String? from,
    String? to,
    String? startFrom,
    String? startTo,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/activities',
        queryParameters: {
          if (type != null) 'activity_type': type.name,
          if (phase != null) 'phase': phase,
          if (statusId != null) 'status_id': statusId,
          if (assigneeId != null) 'assignee_id': assigneeId,
          if (entityType != null) 'entity_type': entityType,
          if (entityId != null) 'entity_id': entityId,
          if (from != null) 'from': from,
          if (to != null) 'to': to,
          if (startFrom != null) 'start_from': startFrom,
          if (startTo != null) 'start_to': startTo,
          'page': page,
          'per_page': perPage,
        },
      );
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list
          .cast<Map<String, dynamic>>()
          .map(ActivityModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch activities',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Create any activity type via POST /api/activities.
  /// For meetings, use ActivityModel.createMeetingPayload() to build the data.
  Future<ActivityModel> createActivity(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/activities',
        data: data,
      );
      return ActivityModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to create activity',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ActivityModel> updateActivity(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/activities/$id',
        data: data,
      );
      return ActivityModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update activity',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> deleteActivity(String id) async {
    try {
      await _dio.delete<void>('/api/activities/$id');
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete activity',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> addLink(
    String activityId,
    String entityType,
    String entityId,
  ) async {
    try {
      await _dio.post<void>(
        '/api/activities/$activityId/links',
        data: {'entity_type': entityType, 'entity_id': entityId},
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to add link',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> removeLink(String activityId, String linkId) async {
    try {
      await _dio.delete<void>(
        '/api/activities/$activityId/links/$linkId',
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to remove link',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Fetch activity statuses for dropdown pickers.
  Future<List<Map<String, dynamic>>> getStatuses(String activityType) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/activity-statuses',
        queryParameters: {'activity_type': activityType},
      );
      final list = response.data?['data'] as List<dynamic>?;
      return list?.cast<Map<String, dynamic>>() ?? [];
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch statuses',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Fetch activity subtypes for dropdown pickers.
  Future<List<Map<String, dynamic>>> getSubtypes(String activityType) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/activity-subtypes',
        queryParameters: {'activity_type': activityType},
      );
      final list = response.data?['data'] as List<dynamic>?;
      return list?.cast<Map<String, dynamic>>() ?? [];
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch subtypes',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
