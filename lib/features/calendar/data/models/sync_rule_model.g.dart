// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_rule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncRuleModel _$SyncRuleModelFromJson(Map<String, dynamic> json) =>
    SyncRuleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      calendarId: json['calendar_id'] as String,
      targetPipelineId: json['target_pipeline_id'] as String,
      targetStageId: json['target_stage_id'] as String,
      isActive: json['is_active'] as bool,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$SyncRuleModelToJson(SyncRuleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'calendar_id': instance.calendarId,
      'target_pipeline_id': instance.targetPipelineId,
      'target_stage_id': instance.targetStageId,
      'is_active': instance.isActive,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
    };
