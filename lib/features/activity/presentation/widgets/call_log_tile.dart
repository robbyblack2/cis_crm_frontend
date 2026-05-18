import 'package:cis_crm/features/activity/domain/entities/call_direction.dart';
import 'package:cis_crm/features/activity/domain/entities/call_log.dart';
import 'package:cis_crm/features/activity/domain/entities/call_outcome.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class CallLogTile extends StatelessWidget {
  const CallLogTile({required this.log, super.key});

  final CallLog log;

  IconData _directionIcon(CallDirection direction) {
    return switch (direction) {
      CallDirection.inbound => Icons.phone_callback,
      CallDirection.outbound => Icons.phone_forwarded,
    };
  }

  String _outcomeLabel(BuildContext context, CallOutcome outcome) {
    final l10n = AppLocalizations.of(context)!;
    return switch (outcome) {
      CallOutcome.connected => l10n.callOutcomeConnected,
      CallOutcome.voicemail => l10n.callOutcomeVoicemail,
      CallOutcome.noAnswer => l10n.callOutcomeNoAnswer,
      CallOutcome.busy => l10n.callOutcomeBusy,
    };
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '--';
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes}m ${remaining}s';
  }

  String _formatTimestamp(DateTime timestamp) {
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '${timestamp.year}-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        _directionIcon(log.direction),
        color:
            log.direction == CallDirection.inbound ? Colors.blue : Colors.green,
      ),
      title: Text(
        log.contactId,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        '${_outcomeLabel(context, log.outcome)}'
        ' \u2022 ${_formatDuration(log.durationSeconds)}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        _formatTimestamp(log.createdAt),
        style: theme.textTheme.labelSmall,
      ),
    );
  }
}
