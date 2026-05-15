import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/automation/domain/entities/automation_rule.dart';
import 'package:cis_crm/features/automation/domain/entities/execution_log.dart';

abstract interface class AutomationRepository {
  Future<Result<List<AutomationRule>, AppFailure>> getRules();

  Future<Result<AutomationRule, AppFailure>> getRule(String id);

  Future<Result<AutomationRule, AppFailure>> createRule(AutomationRule rule);

  Future<Result<AutomationRule, AppFailure>> updateRule(AutomationRule rule);

  Future<Result<void, AppFailure>> deleteRule(String id);

  Future<Result<AutomationRule, AppFailure>> toggleRule(String id);

  Future<Result<ExecutionLog, AppFailure>> dryRunRule(String id);

  Future<Result<List<ExecutionLog>, AppFailure>> getExecutionLogs();
}
