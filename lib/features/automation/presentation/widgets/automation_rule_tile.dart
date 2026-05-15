import 'package:cis_crm/features/automation/domain/entities/automation_rule.dart';
import 'package:flutter/material.dart';

class AutomationRuleTile extends StatelessWidget {
  const AutomationRuleTile({required this.rule, super.key});

  final AutomationRule rule;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(rule.name),
      subtitle: Text(rule.triggerType),
      trailing: Switch(
        value: rule.isActive,
        onChanged: null,
      ),
    );
  }
}
