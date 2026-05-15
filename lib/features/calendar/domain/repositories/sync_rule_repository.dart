import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/calendar/domain/entities/sync_rule.dart';

abstract interface class SyncRuleRepository {
  Future<Result<List<SyncRule>, AppFailure>> getSyncRules();
  Future<Result<SyncRule, AppFailure>> createSyncRule(SyncRule rule);
  Future<Result<SyncRule, AppFailure>> updateSyncRule(SyncRule rule);
  Future<Result<void, AppFailure>> deleteSyncRule(String id);
}
