import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:cis_crm/features/activity/data/models/activity_model.dart';
import 'package:cis_crm/features/activity/data/models/call_log_model.dart';
import 'package:cis_crm/features/activity/data/models/crm_task_model.dart';
import 'package:cis_crm/features/activity/data/models/timeline_entry_model.dart';
import 'package:dio/dio.dart';

class ActivityRemoteDataSourceImpl implements ActivityRemoteDataSource {
  const ActivityRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<ActivityModel>> getActivities({
    required String from,
    required String to,
    int perPage = 100,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/activities',
        queryParameters: {
          'from': from,
          'to': to,
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
  Future<List<CrmTaskModel>> getTasks() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/tasks');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list
          .cast<Map<String, dynamic>>()
          .map(CrmTaskModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch tasks',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CrmTaskModel> getTask(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/tasks/$id');
      return CrmTaskModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch task',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CrmTaskModel> createTask(CrmTaskModel task) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/tasks',
        data: task.toJson(),
      );
      return CrmTaskModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to create task',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CrmTaskModel> updateTask(CrmTaskModel task) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/tasks/${task.id}',
        data: task.toJson(),
      );
      return CrmTaskModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update task',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      await _dio.delete<void>('/api/tasks/$id');
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete task',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<CallLogModel>> getCallLogs() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/call-logs');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list
          .cast<Map<String, dynamic>>()
          .map(CallLogModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch call logs',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CallLogModel> logCall(CallLogModel callLog) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/call-logs',
        data: callLog.toJson(),
      );
      return CallLogModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to log call',
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
