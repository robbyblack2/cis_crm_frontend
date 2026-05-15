import 'package:flutter/material.dart';

class AutomationRuleDetailPage extends StatelessWidget {
  const AutomationRuleDetailPage({required this.ruleId, super.key});

  final String ruleId;

  @override
  Widget build(BuildContext context) {
    // NOTE: The detail view is a placeholder; the bloc no longer has a
    // detail-load event.  Just show a simple scaffold.
    return Scaffold(
      appBar: AppBar(title: const Text('Rule Detail')),
      body: Center(
        child: Text(
          'Detail for rule $ruleId — coming soon.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
