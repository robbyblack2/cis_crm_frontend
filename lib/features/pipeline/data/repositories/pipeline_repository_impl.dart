import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/pipeline/data/datasources/pipeline_remote_data_source.dart';
import 'package:cis_crm/features/pipeline/domain/entities/pipeline.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage.dart';
import 'package:cis_crm/features/pipeline/domain/repositories/pipeline_repository.dart';

class PipelineRepositoryImpl implements PipelineRepository {
  const PipelineRepositoryImpl({
    required PipelineRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final PipelineRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Pipeline>, AppFailure>> getPipelines() async {
    try {
      final pipelines = await _remoteDataSource.getPipelines();
      return Success(pipelines);
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
  Future<Result<({Pipeline pipeline, List<Stage> stages}), AppFailure>>
      getKanban(String pipelineId) async {
    try {
      final result = await _remoteDataSource.getKanban(pipelineId);
      return Success(
        (pipeline: result.pipeline, stages: result.stages),
      );
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
  Future<Result<Pipeline, AppFailure>> createPipeline({
    required String name,
    required PipelineType pipelineType,
  }) async {
    try {
      final pipeline = await _remoteDataSource.createPipeline(
        name: name,
        pipelineType: pipelineType,
      );
      return Success(pipeline);
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
  Future<Result<Pipeline, AppFailure>> updatePipeline({
    required String id,
    required String name,
    required bool isActive,
  }) async {
    try {
      final pipeline = await _remoteDataSource.updatePipeline(
        id: id,
        name: name,
        isActive: isActive,
      );
      return Success(pipeline);
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
  Future<Result<void, AppFailure>> deletePipeline(String id) async {
    try {
      await _remoteDataSource.deletePipeline(id);
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
}
