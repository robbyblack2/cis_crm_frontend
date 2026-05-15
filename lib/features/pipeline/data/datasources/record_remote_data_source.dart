import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/pipeline/data/models/record_model.dart';
import 'package:cis_crm/features/pipeline/data/models/stage_transition_model.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:dio/dio.dart';

abstract class RecordRemoteDataSource {
  Future<List<RecordModel>> getRecords();

  Future<RecordModel> getRecord(String id);

  Future<RecordModel> createRecord({
    required String pipelineId,
    required String stageId,
    required String title,
    required RecordSource source,
  });

  Future<RecordModel> updateRecord({
    required String id,
    required String title,
    List<String>? tags,
  });

  Future<void> deleteRecord(String id);

  Future<RecordModel> moveRecord({
    required String id,
    required String toStageId,
  });

  Future<List<StageTransitionModel>> getStageHistory(String recordId);
}

class RecordRemoteDataSourceImpl implements RecordRemoteDataSource {
  const RecordRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<RecordModel>> getRecords() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/records');
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(RecordModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch records',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<RecordModel> getRecord(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/records/$id');
      return RecordModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch record',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<RecordModel> createRecord({
    required String pipelineId,
    required String stageId,
    required String title,
    required RecordSource source,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/records',
        data: {
          'pipeline_id': pipelineId,
          'stage_id': stageId,
          'title': title,
          'source': source.name,
        },
      );
      return RecordModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to create record',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<RecordModel> updateRecord({
    required String id,
    required String title,
    List<String>? tags,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/records/$id',
        data: {
          'title': title,
          if (tags != null) 'tags': tags,
        },
      );
      return RecordModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update record',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteRecord(String id) async {
    try {
      await _dio.delete<void>('/api/records/$id');
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete record',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<RecordModel> moveRecord({
    required String id,
    required String toStageId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/records/$id/move',
        data: {'to_stage_id': toStageId},
      );
      return RecordModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to move record',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<StageTransitionModel>> getStageHistory(String recordId) async {
    try {
      final response =
          await _dio.get<List<dynamic>>('/api/records/$recordId/stage-history');
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(StageTransitionModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch stage history',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
