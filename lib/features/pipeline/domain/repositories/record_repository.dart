import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/core/pagination/paginated_response.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage_transition.dart';

abstract class RecordRepository {
  Future<Result<PaginatedResponse<PipelineRecord>, AppFailure>> getRecords({
    int page = 1,
    int perPage = 25,
  });

  Future<Result<PipelineRecord, AppFailure>> getRecord(String id);

  Future<Result<PipelineRecord, AppFailure>> createRecord({
    required String pipelineId,
    required String stageId,
    required String title,
    required RecordSource source,
    String? contactId,
    String? companyId,
    List<String> tags,
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
    Map<String, dynamic>? promptData,
  });

  Future<Result<List<StageTransition>, AppFailure>> getStageHistory(
    String recordId,
  );

  Future<Result<PipelineRecord, AppFailure>> claimRecord(String recordId);
}
