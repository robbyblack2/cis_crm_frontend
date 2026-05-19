import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/calendar/data/datasources/calendar_remote_data_source.dart';
import 'package:cis_crm/features/calendar/data/models/calendar_event_model.dart';
import 'package:cis_crm/features/calendar/data/models/sync_rule_model.dart';
import 'package:cis_crm/features/calendar/domain/entities/calendar_event.dart';
import 'package:cis_crm/features/calendar/domain/entities/sync_rule.dart';
import 'package:cis_crm/features/calendar/domain/repositories/calendar_repository.dart';

final class CalendarRepositoryImpl implements CalendarRepository {
  const CalendarRepositoryImpl({
    required CalendarRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final CalendarRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<CalendarEvent>, AppFailure>> getEvents() async {
    try {
      final events = await _remoteDataSource.getEvents();
      return Success(events);
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
  Future<Result<CalendarEvent, AppFailure>> createEvent(
    CalendarEvent event,
  ) async {
    try {
      final model = CalendarEventModel.fromEntity(event);
      final created = await _remoteDataSource.createEvent(model);
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
  Future<Result<CalendarEvent, AppFailure>> updateEvent(
    CalendarEvent event,
  ) async {
    try {
      final model = CalendarEventModel.fromEntity(event);
      final updated = await _remoteDataSource.updateEvent(model);
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
  Future<Result<void, AppFailure>> deleteEvent(String id) async {
    try {
      await _remoteDataSource.deleteEvent(id);
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

  // ── Sync Rules ──

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
      final created = await _remoteDataSource.createSyncRule(model.toJson());
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
      final updated =
          await _remoteDataSource.updateSyncRule(model.id, model.toJson());
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
