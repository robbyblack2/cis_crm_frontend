import 'package:cis_crm/features/activity/domain/entities/call_direction.dart';
import 'package:cis_crm/features/activity/domain/entities/call_log.dart';
import 'package:cis_crm/features/activity/domain/entities/call_outcome.dart';
import 'package:json_annotation/json_annotation.dart';

part 'call_log_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CallLogModel extends CallLog {
  const CallLogModel({
    required super.id,
    required super.contactId,
    required super.direction,
    required super.outcome,
    required super.loggedBy,
    required super.createdAt,
    super.recordId,
    super.durationSeconds,
    super.notes,
  });

  factory CallLogModel.fromJson(Map<String, dynamic> json) =>
      _$CallLogModelFromJson(json);

  factory CallLogModel.fromEntity(CallLog callLog) => CallLogModel(
        id: callLog.id,
        contactId: callLog.contactId,
        direction: callLog.direction,
        outcome: callLog.outcome,
        loggedBy: callLog.loggedBy,
        createdAt: callLog.createdAt,
        recordId: callLog.recordId,
        durationSeconds: callLog.durationSeconds,
        notes: callLog.notes,
      );

  Map<String, dynamic> toJson() => _$CallLogModelToJson(this);
}
