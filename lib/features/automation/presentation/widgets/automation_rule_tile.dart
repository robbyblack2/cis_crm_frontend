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
    return ListTile(
      leading: Icon(
        Icons.bolt_outlined,
        color: rule.isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
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
        message: rule.isActive ? AppLocalizations.of(context)!.deactivateRule : AppLocalizations.of(context)!.activateRule,
        child: Switch(
          value: rule.isActive,
          onChanged: onToggle,
        ),
      ),
      onTap: onTap,
    );
  }

  static String _displayTriggerType(String triggerType) {
    return triggerType.replaceAll('_', ' ').replaceFirstMapped(
          RegExp('^[a-z]'),
          (match) => match.group(0)!.toUpperCase(),
        );
  }
}
