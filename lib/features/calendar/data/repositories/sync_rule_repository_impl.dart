import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/calendar/data/datasources/sync_rule_remote_data_source.dart';
import 'package:cis_crm/features/calendar/data/models/sync_rule_model.dart';
import 'package:cis_crm/features/calendar/domain/entities/sync_rule.dart';
import 'package:cis_crm/features/calendar/domain/repositories/sync_rule_repository.dart';

final class SyncRuleRepositoryImpl implements SyncRuleRepository {
  const SyncRuleRepositoryImpl({
    required SyncRuleRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final SyncRuleRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<SyncRule>, AppFailure>> getSyncRules() async {
    try {
      final rules = await _remoteDataSource.getSyncRules();
      return Success(rules);
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
  Future<Result<SyncRule, AppFailure>> createSyncRule(SyncRule rule) async {
    try {
      final model = SyncRuleModel.fromEntity(rule);
      final created = await _remoteDataSource.createSyncRule(model);
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
  Future<Result<SyncRule, AppFailure>> updateSyncRule(SyncRule rule) async {
    try {
      final model = SyncRuleModel.fromEntity(rule);
      final updated = await _remoteDataSource.updateSyncRule(model);
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
  Future<Result<void, AppFailure>> deleteSyncRule(String id) async {
    try {
      await _remoteDataSource.deleteSyncRule(id);
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
