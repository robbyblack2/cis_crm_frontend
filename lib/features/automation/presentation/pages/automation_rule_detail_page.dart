import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/automation/domain/entities/automation_rule.dart';
import 'package:cis_crm/features/automation/domain/repositories/automation_repository.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class AutomationRuleDetailPage extends StatefulWidget {
  const AutomationRuleDetailPage({required this.ruleId, super.key});

  final String ruleId;

  @override
  State<AutomationRuleDetailPage> createState() =>
      _AutomationRuleDetailPageState();
}

class _AutomationRuleDetailPageState extends State<AutomationRuleDetailPage> {
  AutomationRule? _rule;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRule();
  }

  Future<void> _loadRule() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result =
        await getIt<AutomationRepository>().getRule(widget.ruleId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success(:final data):
          _rule = data;
        case Failure(:final error):
          _error = error.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.ruleDetail)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _rule == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.ruleDetail)),
        body: Center(child: Text(_error ?? 'Rule not found')),
      );
    }

    final rule = _rule!;

    return Scaffold(
      appBar: AppBar(
        title: Text(rule.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            tooltip: l10n.delete,
            onPressed: () => _confirmDelete(context, rule),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info card ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Row(
                      label: 'Status',
                      child: Switch(
                        value: rule.isActive,
                        onChanged: (_) {
                          // Toggle would require passing bloc
                        },
                      ),
                    ),
                    _Row(label: 'Trigger', value: rule.triggerType),
                    _Row(
                      label: 'Priority',
                      value: rule.priority.toString(),
                    ),
                    if (rule.description != null)
                      _Row(
                        label: 'Description',
                        value: rule.description!,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Conditions ──
            Text(
              'Conditions',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: rule.triggerConditions != null &&
                        rule.triggerConditions!.isNotEmpty
                    ? _buildConditions(rule.triggerConditions!)
                    : Text(
                        'No conditions — triggers on all events',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Actions ──
            Text(
              'Actions',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (rule.actions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No actions configured',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...rule.actions.map(
                (action) => Card(
                  child: ListTile(
                    leading: Icon(_actionIcon(
                      action['type'] as String? ?? '',
                    )),
                    title: Text(action['type'] as String? ?? 'Unknown'),
                    subtitle: Text(_actionSummary(action)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditions(Map<String, dynamic> conditions) {
    final operator = conditions['operator'] as String? ?? 'AND';
    final condList =
        conditions['conditions'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Operator: $operator'),
        const SizedBox(height: 8),
        for (final cond in condList)
          if (cond is Map<String, dynamic>)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${cond['field']} ${cond['op']} ${cond['value']}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
      ],
    );
  }

  String _actionSummary(Map<String, dynamic> action) {
    final type = action['type'] as String?;
    return switch (type) {
      'create_task' =>
        'Title: ${action['title'] ?? '—'}, Priority: ${action['priority'] ?? '—'}',
      'send_email' => 'Template: ${action['template_id'] ?? '—'}',
      'move_stage' => 'Stage: ${action['stage_id'] ?? '—'}',
      'assign_user' => 'User: ${action['user_id'] ?? 'round_robin'}',
      'add_tag' => 'Tag: ${action['tag'] ?? '—'}',
      'send_webhook' =>
        '${action['method'] ?? 'POST'} ${action['url'] ?? '—'}',
      _ => action.toString(),
    };
  }

  IconData _actionIcon(String type) {
    return switch (type) {
      'create_task' => Icons.task_alt,
      'send_email' => Icons.email_outlined,
      'move_stage' => Icons.swap_horiz,
      'assign_user' => Icons.person_add_outlined,
      'add_tag' => Icons.label_outline,
      'update_field' => Icons.edit_outlined,
      'send_webhook' => Icons.webhook,
      _ => Icons.bolt_outlined,
    };
  }

  void _confirmDelete(BuildContext context, AutomationRule rule) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteRecord),
        content: Text(l10n.deleteRecordConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true || !context.mounted) return;
      final result =
          await getIt<AutomationRepository>().deleteRule(rule.id);
      if (!context.mounted) return;
      switch (result) {
        case Success():
          Navigator.of(context).pop();
        case Failure():
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.comingSoon)),
          );
      }
    });
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, this.value, this.child});

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          if (child != null) child! else Expanded(child: Text(value ?? '')),
        ],
      ),
    );
  }
}
