import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/automation/data/models/automation_rule_model.dart';
import 'package:cis_crm/features/automation/data/models/execution_log_model.dart';
import 'package:dio/dio.dart';

abstract interface class AutomationRemoteDataSource {
  Future<List<AutomationRuleModel>> getRules();
  Future<AutomationRuleModel> getRule(String id);
  Future<AutomationRuleModel> createRule(Map<String, dynamic> data);
  Future<AutomationRuleModel> updateRule(String id, Map<String, dynamic> data);
  Future<void> deleteRule(String id);
  Future<AutomationRuleModel> toggleRule(String id);
  Future<ExecutionLogModel> dryRunRule(String id);
  Future<List<ExecutionLogModel>> getExecutionLogs();
}

class AutomationRemoteDataSourceImpl implements AutomationRemoteDataSource {
  const AutomationRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const _basePath = '/api/automation';

  @override
  Future<List<AutomationRuleModel>> getRules() async {
    try {
      final response = await _dio.get<List<dynamic>>('$_basePath/rules');
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(AutomationRuleModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch rules',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<AutomationRuleModel> getRule(String id) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('$_basePath/rules/$id');
      return AutomationRuleModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch rule',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<AutomationRuleModel> createRule(Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post<Map<String, dynamic>>('$_basePath/rules', data: data);
      return AutomationRuleModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to create rule',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<AutomationRuleModel> updateRule(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio
          .put<Map<String, dynamic>>('$_basePath/rules/$id', data: data);
      return AutomationRuleModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update rule',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteRule(String id) async {
    try {
      await _dio.delete<void>('$_basePath/rules/$id');
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete rule',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<AutomationRuleModel> toggleRule(String id) async {
    try {
      final response =
          await _dio.post<Map<String, dynamic>>('$_basePath/rules/$id/toggle');
      return AutomationRuleModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to toggle rule',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ExecutionLogModel> dryRunRule(String id) async {
    try {
      final response =
          await _dio.post<Map<String, dynamic>>('$_basePath/rules/$id/dry-run');
      return ExecutionLogModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to dry-run rule',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<ExecutionLogModel>> getExecutionLogs() async {
    try {
      final response =
          await _dio.get<List<dynamic>>('$_basePath/execution-log');
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(ExecutionLogModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch execution logs',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
