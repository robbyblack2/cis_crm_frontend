import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/pagination/paginated_response.dart';
import 'package:cis_crm/features/pipeline/data/models/record_model.dart';
import 'package:cis_crm/features/pipeline/data/models/stage_transition_model.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:dio/dio.dart';

abstract class RecordRemoteDataSource {
  Future<PaginatedResponse<RecordModel>> getRecords({
    int page = 1,
    int perPage = 25,
  });

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
  Future<PaginatedResponse<RecordModel>> getRecords({
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/records',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response body');
      }
      final data = (body['data'] as List<dynamic>?) ?? [];
      final meta = body['meta'] as Map<String, dynamic>? ?? {};
      final items =
          data.cast<Map<String, dynamic>>().map(RecordModel.fromJson).toList();
      return PaginatedResponse<RecordModel>(
        items: items,
        page: meta['page'] as int? ?? page,
        perPage: meta['per_page'] as int? ?? perPage,
        total: meta['total'] as int? ?? items.length,
      );
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
      return RecordModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
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
      return RecordModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
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
      return RecordModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
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
      return RecordModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
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
      final response = await _dio
          .get<Map<String, dynamic>>('/api/records/$recordId/stage-history');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list
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
