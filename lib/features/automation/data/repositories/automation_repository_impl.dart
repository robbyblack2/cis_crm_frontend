import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/automation/data/datasources/automation_remote_data_source.dart';
import 'package:cis_crm/features/automation/data/models/automation_rule_model.dart';
import 'package:cis_crm/features/automation/domain/entities/automation_rule.dart';
import 'package:cis_crm/features/automation/domain/entities/execution_log.dart';
import 'package:cis_crm/features/automation/domain/repositories/automation_repository.dart';

class AutomationRepositoryImpl implements AutomationRepository {
  const AutomationRepositoryImpl({
    required AutomationRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AutomationRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<AutomationRule>, AppFailure>> getRules() async {
    try {
      final rules = await _remoteDataSource.getRules();
      return Success(rules);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<AutomationRule, AppFailure>> getRule(String id) async {
    try {
      final rule = await _remoteDataSource.getRule(id);
      return Success(rule);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<AutomationRule, AppFailure>> createRule(
    AutomationRule rule,
  ) async {
    try {
      final model = rule as AutomationRuleModel;
      final created = await _remoteDataSource.createRule(model.toJson());
      return Success(created);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<AutomationRule, AppFailure>> updateRule(
    AutomationRule rule,
  ) async {
    try {
      final model = rule as AutomationRuleModel;
      final updated =
          await _remoteDataSource.updateRule(model.id, model.toJson());
      return Success(updated);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<void, AppFailure>> deleteRule(String id) async {
    try {
      await _remoteDataSource.deleteRule(id);
      return const Success(null);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<AutomationRule, AppFailure>> toggleRule(String id) async {
    try {
      final rule = await _remoteDataSource.toggleRule(id);
      return Success(rule);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<ExecutionLog, AppFailure>> dryRunRule(String id) async {
    try {
      final log = await _remoteDataSource.dryRunRule(id);
      return Success(log);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<List<ExecutionLog>, AppFailure>> getExecutionLogs() async {
    try {
      final logs = await _remoteDataSource.getExecutionLogs();
      return Success(logs);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }
}
