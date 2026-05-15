import 'package:cis_crm/features/automation/data/datasources/automation_remote_data_source.dart';
import 'package:cis_crm/features/automation/data/models/automation_rule_model.dart';
import 'package:cis_crm/features/automation/data/models/execution_log_model.dart';
import 'package:cis_crm/features/automation/domain/entities/execution_status.dart';
import 'package:cis_crm/features/automation/domain/repositories/automation_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAutomationRepository extends Mock implements AutomationRepository {}

class MockAutomationRemoteDataSource extends Mock
    implements AutomationRemoteDataSource {}

AutomationRuleModel createTestRuleModel({
  String id = 'rule-1',
  String name = 'Test Rule',
  String? description = 'A test rule',
  bool isActive = true,
  String triggerType = 'on_create',
  int priority = 1,
  String createdBy = 'user-1',
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.utc(2026);
  return AutomationRuleModel(
    id: id,
    name: name,
    description: description,
    isActive: isActive,
    triggerType: triggerType,
    priority: priority,
    createdBy: createdBy,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

ExecutionLogModel createTestLogModel({
  String id = 'log-1',
  String ruleId = 'rule-1',
  String correlationId = 'corr-1',
  ExecutionStatus status = ExecutionStatus.success,
  String? errorDetail,
  DateTime? createdAt,
}) {
  return ExecutionLogModel(
    id: id,
    ruleId: ruleId,
    correlationId: correlationId,
    status: status,
    errorDetail: errorDetail,
    createdAt: createdAt ?? DateTime.utc(2026),
  );
}
