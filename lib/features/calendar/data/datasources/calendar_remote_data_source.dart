import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/calendar/data/models/calendar_event_model.dart';
import 'package:dio/dio.dart';

abstract interface class CalendarRemoteDataSource {
  Future<List<CalendarEventModel>> getEvents();
  Future<CalendarEventModel> createEvent(CalendarEventModel event);
  Future<CalendarEventModel> updateEvent(CalendarEventModel event);
  Future<void> deleteEvent(String id);
}

final class CalendarRemoteDataSourceImpl implements CalendarRemoteDataSource {
  const CalendarRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const _basePath = '/api/calendar/events';

  @override
  Future<List<CalendarEventModel>> getEvents() async {
    try {
      final response = await _dio.get<List<dynamic>>(_basePath);
      final data = response.data;
      if (data == null) {
        throw const ServerException('Empty response body');
      }
      return data
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
      final data = response.data;
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
      final data = response.data;
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
}
