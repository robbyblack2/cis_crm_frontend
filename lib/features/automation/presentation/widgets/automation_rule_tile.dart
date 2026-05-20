import 'package:cis_crm/features/automation/domain/entities/automation_rule.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class AutomationRuleTile extends StatelessWidget {
  const AutomationRuleTile({
    required this.rule,
    this.onTap,
    this.onToggle,
    super.key,
  });

  final AutomationRule rule;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: rule.isActive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          _triggerIcon(rule.triggerType),
          color: rule.isActive
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
      title: Text(
        rule.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _displayTriggerType(rule.triggerType),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Tooltip(
        message: rule.isActive ? l10n.deactivateRule : l10n.activateRule,
        child: Switch(
          value: rule.isActive,
          onChanged: onToggle,
        ),
      ),
      onTap: onTap,
    );
  }

  static IconData _triggerIcon(String triggerType) {
    return switch (triggerType) {
      'record.stage_changed' => Icons.swap_horiz,
      'record.created' => Icons.add_box_outlined,
      'record.updated' => Icons.edit_outlined,
      'contact.created' => Icons.person_add_outlined,
      'contact.updated' => Icons.person_outline,
      'task.created' => Icons.task_alt,
      'task.completed' => Icons.check_circle_outline,
      'email.received' => Icons.email_outlined,
      _ => Icons.bolt_outlined,
    };
  }

  static String _displayTriggerType(String triggerType) {
    return triggerType.replaceAll('_', ' ').replaceFirstMapped(
          RegExp('^[a-z]'),
          (match) => match.group(0)!.toUpperCase(),
        );
  }
}
