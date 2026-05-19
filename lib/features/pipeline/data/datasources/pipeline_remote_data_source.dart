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

  Future<List<StageModel>> getStages(String pipelineId);

  Future<StageModel> createStage({
    required String pipelineId,
    required String name,
    required int position,
    String color,
    String stageType,
  });

  Future<StageModel> updateStage({
    required String id,
    required String name,
    required int position,
    String? color,
  });

  Future<void> deleteStage(String id);

  Future<List<Map<String, dynamic>>> getStagePrompts(String stageId);
  Future<Map<String, dynamic>> createStagePrompt(
    String stageId,
    Map<String, dynamic> data,
  );
  Future<Map<String, dynamic>> updateStagePrompt(
    String promptId,
    Map<String, dynamic> data,
  );
  Future<void> deleteStagePrompt(String promptId);
}

class PipelineRemoteDataSourceImpl implements PipelineRemoteDataSource {
  const PipelineRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<PipelineModel>> getPipelines() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/pipelines');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list
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
      // Backend returns {"data": [{stage: {...}, records: [...]}, ...]}
      final list = response.data?['data'] as List<dynamic>? ?? [];
      final stageGroups = list.cast<Map<String, dynamic>>();
      final stages = stageGroups
          .map(
            (g) =>
                StageModel.fromJson(g['stage'] as Map<String, dynamic>),
          )
          .toList();
      final pipeline = PipelineModel(
        id: pipelineId,
        name: '',
        sortOrder: 0,
        pipelineType: PipelineType.sales,
        isActive: true,
        createdAt: DateTime.now(),
      );
      return (pipeline: pipeline, stages: stages);
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
      return PipelineModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
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
      return PipelineModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update pipeline',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<StageModel>> getStages(String pipelineId) async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>('/api/pipelines/$pipelineId/stages');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list
          .cast<Map<String, dynamic>>()
          .map(StageModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch stages',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<StageModel> createStage({
    required String pipelineId,
    required String name,
    required int position,
    String color = '#9E9E9E',
    String stageType = 'normal',
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/pipelines/$pipelineId/stages',
        data: {
          'name': name,
          'position': position,
          'color': color,
          'stage_type': stageType,
        },
      );
      return StageModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to create stage',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<StageModel> updateStage({
    required String id,
    required String name,
    required int position,
    String? color,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/stages/$id',
        data: {
          'name': name,
          'position': position,
          if (color != null) 'color': color,
        },
      );
      return StageModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update stage',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteStage(String id) async {
    try {
      await _dio.delete<void>('/api/stages/$id');
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete stage',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStagePrompts(
    String stageId,
  ) async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>('/api/stages/$stageId/prompts');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch stage prompts',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> createStagePrompt(
    String stageId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/stages/$stageId/prompts',
        data: data,
      );
      return response.data?['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to create stage prompt',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> updateStagePrompt(
    String promptId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/stage-prompts/$promptId',
        data: data,
      );
      return response.data?['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update stage prompt',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteStagePrompt(String promptId) async {
    try {
      await _dio.delete<void>('/api/stage-prompts/$promptId');
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete stage prompt',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
