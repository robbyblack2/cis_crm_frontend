import 'package:cis_crm/features/automation/domain/entities/automation_rule.dart';
import 'package:flutter/material.dart';

class AutomationRuleDetailPage extends StatelessWidget {
  const AutomationRuleDetailPage({required this.rule, super.key});

  final AutomationRule rule;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(rule.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trigger: ${rule.triggerType}'),
            const SizedBox(height: 8),
            Text('Priority: ${rule.priority}'),
            const SizedBox(height: 8),
            Text('Active: ${rule.isActive}'),
            if (rule.description != null) ...[
              const SizedBox(height: 8),
              Text(rule.description!),
            ],
          ],
        ),
      ),
    );
  }
}
