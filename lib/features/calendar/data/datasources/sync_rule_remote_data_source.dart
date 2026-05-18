import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/calendar/data/models/sync_rule_model.dart';
import 'package:dio/dio.dart';

abstract interface class SyncRuleRemoteDataSource {
  Future<List<SyncRuleModel>> getSyncRules();
  Future<SyncRuleModel> createSyncRule(SyncRuleModel rule);
  Future<SyncRuleModel> updateSyncRule(SyncRuleModel rule);
  Future<void> deleteSyncRule(String id);
}

final class SyncRuleRemoteDataSourceImpl implements SyncRuleRemoteDataSource {
  const SyncRuleRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const _basePath = '/api/calendar/sync-rules';

  @override
  Future<List<SyncRuleModel>> getSyncRules() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_basePath);
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
  Future<SyncRuleModel> createSyncRule(SyncRuleModel rule) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _basePath,
        data: rule.toJson(),
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Empty response body');
      }
      return SyncRuleModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to create sync rule',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<SyncRuleModel> updateSyncRule(SyncRuleModel rule) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '$_basePath/${rule.id}',
        data: rule.toJson(),
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Empty response body');
      }
      return SyncRuleModel.fromJson(data);
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
      await _dio.delete<void>('$_basePath/$id');
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete sync rule',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
