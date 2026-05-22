import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:cis_crm/features/activity/data/models/activity_model.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:cis_crm/features/activity/data/models/timeline_entry_model.dart';
import 'package:dio/dio.dart';

class ActivityRemoteDataSourceImpl implements ActivityRemoteDataSource {
  const ActivityRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<ActivityModel>> getActivities({
    String? activityType,
    String? statusId,
    String? phase,
    String? assigneeId,
    String? from,
    String? to,
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/activities',
        queryParameters: {
          if (activityType != null) 'activity_type': activityType,
          if (statusId != null) 'status_id': statusId,
          if (phase != null) 'phase': phase,
          if (assigneeId != null) 'assignee_id': assigneeId,
          if (from != null) 'from': from,
          if (to != null) 'to': to,
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

  @override
  Future<ActivityModel> getActivity(String id) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/activities/$id');
      return ActivityModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch activity',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ActivityModel> createActivity(ActivityModel activity) async {
    try {
      // Meetings go through /api/calendar/events which pushes to
      // Google Calendar and generates Meet links. Tasks/calls use
      // the regular /api/activities endpoint.
      final isMeeting = activity.activityType == ActivityType.meeting;
      final endpoint =
          isMeeting ? '/api/calendar/events' : '/api/activities';

      final response = await _dio.post<Map<String, dynamic>>(
        endpoint,
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

  @override
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

  @override
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

  @override
  Future<List<TimelineEntryModel>> getTimeline({
    required String entityType,
    required String entityId,
  }) async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>('/api/timeline/$entityType/$entityId');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list
          .cast<Map<String, dynamic>>()
          .map(TimelineEntryModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch timeline',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
