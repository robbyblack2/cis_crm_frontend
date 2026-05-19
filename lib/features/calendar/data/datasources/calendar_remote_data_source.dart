import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/calendar/data/models/calendar_event_model.dart';
import 'package:cis_crm/features/calendar/data/models/sync_rule_model.dart';
import 'package:dio/dio.dart';

abstract interface class CalendarRemoteDataSource {
  Future<List<CalendarEventModel>> getEvents();
  Future<CalendarEventModel> createEvent(CalendarEventModel event);
  Future<CalendarEventModel> updateEvent(CalendarEventModel event);
  Future<void> deleteEvent(String id);

  Future<List<SyncRuleModel>> getSyncRules();
  Future<SyncRuleModel> createSyncRule(Map<String, dynamic> data);
  Future<SyncRuleModel> updateSyncRule(String id, Map<String, dynamic> data);
  Future<void> deleteSyncRule(String id);
}

final class CalendarRemoteDataSourceImpl implements CalendarRemoteDataSource {
  const CalendarRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const _basePath = '/api/calendar/events';

  @override
  Future<List<CalendarEventModel>> getEvents() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_basePath);
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list
          .cast<Map<String, dynamic>>()
          .map(CalendarEventModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch events',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CalendarEventModel> createEvent(CalendarEventModel event) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _basePath,
        data: event.toJson(),
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Empty response body');
      }
      return CalendarEventModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to create event',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CalendarEventModel> updateEvent(CalendarEventModel event) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '$_basePath/${event.id}',
        data: event.toJson(),
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Empty response body');
      }
      return CalendarEventModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update event',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    try {
      await _dio.delete<void>('$_basePath/$id');
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete event',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── Sync Rules ──

  static const _syncRulesPath = '/api/calendar/sync-rules';

  @override
  Future<List<SyncRuleModel>> getSyncRules() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(_syncRulesPath);
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list
          .cast<Map<String, dynamic>>()
          .map(SyncRuleModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch sync rules',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<SyncRuleModel> createSyncRule(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _syncRulesPath,
        data: data,
      );
      return SyncRuleModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to create sync rule',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<SyncRuleModel> updateSyncRule(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '$_syncRulesPath/$id',
        data: data,
      );
      return SyncRuleModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update sync rule',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteSyncRule(String id) async {
    try {
      await _dio.delete<void>('$_syncRulesPath/$id');
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete sync rule',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
