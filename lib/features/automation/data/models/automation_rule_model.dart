import 'package:cis_crm/features/automation/domain/entities/automation_rule.dart';
import 'package:json_annotation/json_annotation.dart';

part 'automation_rule_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
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
  });

  factory AutomationRuleModel.fromJson(Map<String, dynamic> json) =>
      _$AutomationRuleModelFromJson(json);

  Map<String, dynamic> toJson() => _$AutomationRuleModelToJson(this);
}
