// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'automation_rule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AutomationRuleModel _$AutomationRuleModelFromJson(Map<String, dynamic> json) =>
    AutomationRuleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['is_active'] as bool,
      triggerType: json['trigger_type'] as String,
      priority: (json['priority'] as num).toInt(),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$AutomationRuleModelToJson(
        AutomationRuleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'is_active': instance.isActive,
      'trigger_type': instance.triggerType,
      'priority': instance.priority,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
