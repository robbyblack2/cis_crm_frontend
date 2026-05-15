import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/pipeline/data/models/pipeline_model.dart';
import 'package:cis_crm/features/pipeline/data/models/stage_model.dart';
import 'package:cis_crm/features/pipeline/domain/entities/pipeline.dart';
import 'package:dio/dio.dart';

abstract class PipelineRemoteDataSource {
  Future<List<PipelineModel>> getPipelines();

  Future<({PipelineModel pipeline, List<StageModel> stages})> getKanban(
    String pipelineId,
  );

  Future<PipelineModel> createPipeline({
    required String name,
    required PipelineType pipelineType,
  });

  Future<PipelineModel> updatePipeline({
    required String id,
    required String name,
    required bool isActive,
  });
}

class PipelineRemoteDataSourceImpl implements PipelineRemoteDataSource {
  const PipelineRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<PipelineModel>> getPipelines() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/pipelines');
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(PipelineModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch pipelines',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<({PipelineModel pipeline, List<StageModel> stages})> getKanban(
    String pipelineId,
  ) async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>('/api/pipelines/$pipelineId/kanban');
      final data = response.data!;
      return (
        pipeline: PipelineModel.fromJson(
          data['pipeline'] as Map<String, dynamic>,
        ),
        stages: (data['stages'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(StageModel.fromJson)
            .toList(),
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch kanban data',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<PipelineModel> createPipeline({
    required String name,
    required PipelineType pipelineType,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/pipelines',
        data: {'name': name, 'pipeline_type': pipelineType.name},
      );
      return PipelineModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to create pipeline',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<PipelineModel> updatePipeline({
    required String id,
    required String name,
    required bool isActive,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/pipelines/$id',
        data: {'name': name, 'is_active': isActive},
      );
      return PipelineModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update pipeline',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
