import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/activity/data/models/activity_model.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:dio/dio.dart';

class ActivitiesDataSource {
  const ActivitiesDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<ActivityModel>> getActivities({
    ActivityType? type,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/activities',
        queryParameters: {
          if (type != null) 'activity_type': type.name,
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

  Future<ActivityModel> createActivity(ActivityModel activity) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/activities',
        data: activity.toJson(),
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

  Future<ActivityModel> updateActivity(ActivityModel activity) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/activities/${activity.id}',
        data: activity.toJson(),
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
}
