import 'package:cis_crm/features/calendar/domain/entities/sync_rule.dart';

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
    super.updatedAt,
    super.matchCriteria,
    super.fieldMappings,
  });

  factory SyncRuleModel.fromJson(Map<String, dynamic> json) => SyncRuleModel(
        id: json['id'] as String,
        name: json['name'] as String,
        calendarId: json['calendar_id'] as String? ?? 'primary',
        targetPipelineId: json['target_pipeline_id'] as String,
        targetStageId: json['target_stage_id'] as String,
        isActive: json['is_active'] as bool? ?? true,
        createdBy: json['created_by'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        matchCriteria: json['match_criteria'] as Map<String, dynamic>?,
        fieldMappings: json['field_mappings'] as Map<String, dynamic>?,
      );

  factory SyncRuleModel.fromEntity(SyncRule entity) => SyncRuleModel(
        id: entity.id,
        name: entity.name,
        calendarId: entity.calendarId,
        targetPipelineId: entity.targetPipelineId,
        targetStageId: entity.targetStageId,
        isActive: entity.isActive,
        createdBy: entity.createdBy,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        matchCriteria: entity.matchCriteria,
        fieldMappings: entity.fieldMappings,
      );

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'name': name,
        'calendar_id': calendarId,
        'target_pipeline_id': targetPipelineId,
        'target_stage_id': targetStageId,
        'is_active': isActive,
        if (matchCriteria != null) 'match_criteria': matchCriteria,
        if (fieldMappings != null) 'field_mappings': fieldMappings,
      };
}
