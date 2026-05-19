import 'dart:convert';

import 'package:cis_crm/features/automation/domain/entities/automation_rule.dart';

class AutomationRuleModel extends AutomationRule {
  const AutomationRuleModel({
    required super.id,
    required super.name,
    required super.isActive,
    required super.triggerType,
    required super.priority,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.description,
    super.triggerConditions,
    super.actions,
  });

  factory AutomationRuleModel.fromJson(Map<String, dynamic> json) {
    // Handle trigger_conditions as Map, String, or null
    Map<String, dynamic>? conditions;
    final rawCond = json['trigger_conditions'];
    if (rawCond is Map) {
      conditions = Map<String, dynamic>.from(rawCond);
    } else if (rawCond is String && rawCond.isNotEmpty) {
      try {
        final parsed = jsonDecode(rawCond);
        if (parsed is Map) conditions = Map<String, dynamic>.from(parsed);
      } catch (_) {}
    }

    // Handle actions as List, String, or null
    List<Map<String, dynamic>> actions;
    final rawActions = json['actions'];
    if (rawActions is List) {
      actions = rawActions
          .map((a) => a is Map ? Map<String, dynamic>.from(a) : <String, dynamic>{})
          .toList();
    } else if (rawActions is String && rawActions.isNotEmpty) {
      try {
        final parsed = jsonDecode(rawActions);
        if (parsed is List) {
          actions = parsed
              .map((a) => a is Map ? Map<String, dynamic>.from(a) : <String, dynamic>{})
              .toList();
        } else {
          actions = const [];
        }
      } catch (_) {
        actions = const [];
      }
    } else {
      actions = const [];
    }

    return AutomationRuleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      triggerType: json['trigger_type'] as String,
      triggerConditions: conditions,
      actions: actions,
      priority: json['priority'] as int? ?? 0,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  factory AutomationRuleModel.fromEntity(AutomationRule rule) =>
      AutomationRuleModel(
        id: rule.id,
        name: rule.name,
        description: rule.description,
        isActive: rule.isActive,
        triggerType: rule.triggerType,
        triggerConditions: rule.triggerConditions,
        actions: rule.actions,
        priority: rule.priority,
        createdBy: rule.createdBy,
        createdAt: rule.createdAt,
        updatedAt: rule.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'name': name,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'is_active': isActive,
        'trigger_type': triggerType,
        'trigger_conditions': triggerConditions ?? <String, dynamic>{},
        'actions': actions,
        'priority': priority,
        if (createdBy.isNotEmpty) 'created_by': createdBy,
      };
}
