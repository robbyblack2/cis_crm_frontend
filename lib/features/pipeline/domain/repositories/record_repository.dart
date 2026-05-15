import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage_transition.dart';

abstract class RecordRepository {
  Future<Result<List<PipelineRecord>, AppFailure>> getRecords();

  Future<Result<PipelineRecord, AppFailure>> getRecord(String id);

  Future<Result<PipelineRecord, AppFailure>> createRecord({
    required String pipelineId,
    required String stageId,
    required String title,
    required RecordSource source,
  });

  Future<Result<PipelineRecord, AppFailure>> updateRecord({
    required String id,
    required String title,
    List<String>? tags,
  });

  Future<Result<void, AppFailure>> deleteRecord(String id);

  Future<Result<PipelineRecord, AppFailure>> moveRecord({
    required String id,
    required String toStageId,
  });

  Future<Result<List<StageTransition>, AppFailure>> getStageHistory(
    String recordId,
  );
}
