import 'package:cis_crm/features/automation/domain/entities/execution_log.dart';
import 'package:cis_crm/features/automation/domain/entities/execution_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'execution_log_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ExecutionLogModel extends ExecutionLog {
  const ExecutionLogModel({
    required super.id,
    required super.ruleId,
    required super.correlationId,
    required super.status,
    required super.createdAt,
    super.errorDetail,
  });

  factory ExecutionLogModel.fromJson(Map<String, dynamic> json) =>
      _$ExecutionLogModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExecutionLogModelToJson(this);
}
