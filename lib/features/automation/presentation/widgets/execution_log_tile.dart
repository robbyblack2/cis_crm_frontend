import 'package:cis_crm/features/automation/domain/entities/execution_log.dart';
import 'package:cis_crm/features/automation/domain/entities/execution_status.dart';
import 'package:flutter/material.dart';

class ExecutionLogTile extends StatelessWidget {
  const ExecutionLogTile({required this.log, this.ruleName, super.key});

  final ExecutionLog log;
  final String? ruleName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        _iconForStatus(log.status),
        color: _colorForStatus(log.status, theme),
      ),
      title: Text(
        ruleName ?? 'Rule ${log.ruleId}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_formatTimestamp(log.createdAt)),
      trailing: Chip(
        label: Text(
          _labelForStatus(log.status),
          style: theme.textTheme.labelSmall?.copyWith(
            color: _colorForStatus(log.status, theme),
          ),
        ),
        side: BorderSide(color: _colorForStatus(log.status, theme)),
        backgroundColor: Colors.transparent,
      ),
    );
  }

  static IconData _iconForStatus(ExecutionStatus status) {
    return switch (status) {
      ExecutionStatus.success => Icons.check_circle_outline,
      ExecutionStatus.partialFailure => Icons.warning_amber_outlined,
      ExecutionStatus.failed => Icons.error_outline,
      ExecutionStatus.dryRun => Icons.science_outlined,
    };
  }

  static Color _colorForStatus(ExecutionStatus status, ThemeData theme) {
    return switch (status) {
      ExecutionStatus.success => Colors.green,
      ExecutionStatus.partialFailure => Colors.orange,
      ExecutionStatus.failed => theme.colorScheme.error,
      ExecutionStatus.dryRun => theme.colorScheme.tertiary,
    };
  }

  static String _labelForStatus(ExecutionStatus status) {
    return switch (status) {
      ExecutionStatus.success => 'Success',
      ExecutionStatus.partialFailure => 'Partial',
      ExecutionStatus.failed => 'Failed',
      ExecutionStatus.dryRun => 'Dry Run',
    };
  }

  static String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
