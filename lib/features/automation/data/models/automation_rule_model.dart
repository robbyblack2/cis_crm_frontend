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
    final rawActions = json['actions'] as List<dynamic>?;
    return AutomationRuleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      triggerType: json['trigger_type'] as String,
      triggerConditions:
          json['trigger_conditions'] as Map<String, dynamic>?,
      actions: rawActions
              ?.map((a) => Map<String, dynamic>.from(a as Map))
              .toList() ??
          const [],
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
        if (triggerConditions != null)
          'trigger_conditions': triggerConditions,
        'actions': actions,
        'priority': priority,
      };
}
