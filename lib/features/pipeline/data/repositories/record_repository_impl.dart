import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/core/pagination/paginated_response.dart';
import 'package:cis_crm/features/pipeline/data/datasources/record_remote_data_source.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage_transition.dart';
import 'package:cis_crm/features/pipeline/domain/repositories/record_repository.dart';

class RecordRepositoryImpl implements RecordRepository {
  const RecordRepositoryImpl({
    required RecordRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final RecordRemoteDataSource _remoteDataSource;

  @override
  Future<Result<PaginatedResponse<PipelineRecord>, AppFailure>> getRecords({
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final response = await _remoteDataSource.getRecords(
        page: page,
        perPage: perPage,
      );
      return Success(response);
    } on NetworkException {
      return const Failure(NetworkFailure());
    } on UnauthorizedException {
      return const Failure(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<PipelineRecord, AppFailure>> getRecord(String id) async {
    try {
      final record = await _remoteDataSource.getRecord(id);
      return Success(record);
    } on NetworkException {
      return const Failure(NetworkFailure());
    } on UnauthorizedException {
      return const Failure(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<PipelineRecord, AppFailure>> createRecord({
    required String pipelineId,
    required String stageId,
    required String title,
    required RecordSource source,
    String? contactId,
    String? companyId,
    List<String> tags = const [],
  }) async {
    try {
      final record = await _remoteDataSource.createRecord(
        pipelineId: pipelineId,
        stageId: stageId,
        title: title,
        source: source,
        contactId: contactId,
        companyId: companyId,
        tags: tags,
      );
      return Success(record);
    } on NetworkException {
      return const Failure(NetworkFailure());
    } on UnauthorizedException {
      return const Failure(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<PipelineRecord, AppFailure>> updateRecord({
    required String id,
    required String title,
    List<String>? tags,
  }) async {
    try {
      final record = await _remoteDataSource.updateRecord(
        id: id,
        title: title,
        tags: tags,
      );
      return Success(record);
    } on NetworkException {
      return const Failure(NetworkFailure());
    } on UnauthorizedException {
      return const Failure(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<void, AppFailure>> deleteRecord(String id) async {
    try {
      await _remoteDataSource.deleteRecord(id);
      return const Success(null);
    } on NetworkException {
      return const Failure(NetworkFailure());
    } on UnauthorizedException {
      return const Failure(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<PipelineRecord, AppFailure>> moveRecord({
    required String id,
    required String toStageId,
    Map<String, dynamic>? promptData,
  }) async {
    try {
      final record = await _remoteDataSource.moveRecord(
        id: id,
        toStageId: toStageId,
        promptData: promptData,
      );
      return Success(record);
    } on NetworkException {
      return const Failure(NetworkFailure());
    } on UnauthorizedException {
      return const Failure(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<List<StageTransition>, AppFailure>> getStageHistory(
    String recordId,
  ) async {
    try {
      final history = await _remoteDataSource.getStageHistory(recordId);
      return Success(history);
    } on NetworkException {
      return const Failure(NetworkFailure());
    } on UnauthorizedException {
      return const Failure(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }
}
