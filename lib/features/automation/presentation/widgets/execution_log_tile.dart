import 'package:cis_crm/features/automation/domain/entities/execution_log.dart';
import 'package:flutter/material.dart';

class ExecutionLogTile extends StatelessWidget {
  const ExecutionLogTile({required this.log, super.key});

  final ExecutionLog log;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Rule: ${log.ruleId}'),
      subtitle: Text('Status: ${log.status.name}'),
      trailing: Text(log.createdAt.toIso8601String()),
    );
  }
}
