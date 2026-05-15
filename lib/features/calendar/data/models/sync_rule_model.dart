import 'package:cis_crm/features/calendar/domain/entities/sync_rule.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sync_rule_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SyncRuleModel extends SyncRule {
  const SyncRuleModel({
    required super.id,
    required super.name,
    required super.calendarId,
    required super.targetPipelineId,
    required super.targetStageId,
    required super.isActive,
    required super.createdBy,
    required super.createdAt,
  });

  factory SyncRuleModel.fromJson(Map<String, dynamic> json) =>
      _$SyncRuleModelFromJson(json);

  factory SyncRuleModel.fromEntity(SyncRule entity) => SyncRuleModel(
        id: entity.id,
        name: entity.name,
        calendarId: entity.calendarId,
        targetPipelineId: entity.targetPipelineId,
        targetStageId: entity.targetStageId,
        isActive: entity.isActive,
        createdBy: entity.createdBy,
        createdAt: entity.createdAt,
      );

  Map<String, dynamic> toJson() => _$SyncRuleModelToJson(this);
}
