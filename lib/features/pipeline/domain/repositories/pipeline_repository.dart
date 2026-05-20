import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/pipeline/domain/entities/pipeline.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage.dart';

abstract class PipelineRepository {
  Future<Result<List<Pipeline>, AppFailure>> getPipelines();

  Future<Result<({Pipeline pipeline, List<Stage> stages}), AppFailure>>
      getKanban(String pipelineId);

  Future<Result<Pipeline, AppFailure>> createPipeline({
    required String name,
    required PipelineType pipelineType,
  });

  Future<Result<Pipeline, AppFailure>> updatePipeline({
    required String id,
    required String name,
    required bool isActive,
  });

  Future<Result<void, AppFailure>> deletePipeline(String id);
}
