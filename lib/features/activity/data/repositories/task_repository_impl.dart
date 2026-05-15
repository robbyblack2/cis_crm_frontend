import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:cis_crm/features/activity/data/models/crm_task_model.dart';
import 'package:cis_crm/features/activity/domain/entities/crm_task.dart';
import 'package:cis_crm/features/activity/domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  const TaskRepositoryImpl({
    required ActivityRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final ActivityRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<CrmTask>, AppFailure>> getTasks() async {
    try {
      final tasks = await _remoteDataSource.getTasks();
      return Success(tasks);
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Failure(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<CrmTask, AppFailure>> getTask(String id) async {
    try {
      final task = await _remoteDataSource.getTask(id);
      return Success(task);
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Failure(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<CrmTask, AppFailure>> createTask(CrmTask task) async {
    try {
      final model = CrmTaskModel.fromEntity(task);
      final created = await _remoteDataSource.createTask(model);
      return Success(created);
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Failure(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<CrmTask, AppFailure>> updateTask(CrmTask task) async {
    try {
      final model = CrmTaskModel.fromEntity(task);
      final updated = await _remoteDataSource.updateTask(model);
      return Success(updated);
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Failure(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<void, AppFailure>> deleteTask(String id) async {
    try {
      await _remoteDataSource.deleteTask(id);
      return const Success(null);
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Failure(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }
}
