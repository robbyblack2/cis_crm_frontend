import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/automation/domain/entities/automation_rule.dart';
import 'package:cis_crm/features/automation/domain/repositories/automation_repository.dart';
import 'package:cis_crm/features/automation/presentation/bloc/automation_bloc.dart';
import 'package:cis_crm/features/automation/presentation/pages/automation_builder_page.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final result = await getIt<AutomationRepository>().getRules();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success(:final data):
          final match = data.where((r) => r.id == widget.ruleId);
          if (match.isNotEmpty) {
            _rule = match.first;
          } else {
            _error = 'Rule not found';
          }
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
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Duplicate rule',
            onPressed: () => _duplicateRule(context, rule),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => _openEditor(context, rule),
          ),
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
                        onChanged: (_) async {
                          final result = await getIt<AutomationRepository>()
                              .toggleRule(rule.id);
                          if (!context.mounted) return;
                          switch (result) {
                            case Success(:final data):
                              setState(() => _rule = data);
                            case Failure(:final error):
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Toggle failed: ${error.message}',
                                  ),
                                ),
                              );
                          }
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
            _buildConditionsCards(rule, theme),
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
              ...rule.actions.asMap().entries.map(
                (entry) => _buildActionCard(entry.key, entry.value, theme),
              ),
            const SizedBox(height: 16),

            // ── Dry Run ──
            FilledButton.tonalIcon(
              onPressed: () => _dryRun(context, rule.id),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Dry Run'),
            ),
            const SizedBox(height: 16),

            // ── Execution Log ──
            Text(
              'Execution Log',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _ExecutionLogSection(ruleId: rule.id),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsCards(AutomationRule rule, ThemeData theme) {
    if (rule.triggerConditions == null || rule.triggerConditions!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No conditions — triggers on all events',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final conditions = rule.triggerConditions!;
    final allConds = conditions['All'] as List<dynamic>?;
    final anyConds = conditions['Any'] as List<dynamic>?;
    final legacyConds = conditions['conditions'] as List<dynamic>?;
    final operator = allConds != null
        ? 'All'
        : anyConds != null
            ? 'Any'
            : conditions['operator'] as String? ?? 'All';
    final condList = allConds ?? anyConds ?? legacyConds ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Chip(
          avatar: const Icon(Icons.filter_list, size: 16),
          label: Text('Match: $operator'),
        ),
        const SizedBox(height: 8),
        ...condList.whereType<Map<String, dynamic>>().map(
              (cond) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.rule_outlined,
                    color: theme.colorScheme.tertiary,
                  ),
                  title: Text(
                    '${cond['field']}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  subtitle: Text(
                    '${cond['operator'] ?? cond['op']} ${cond['value']}',
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildActionCard(int index, Map<String, dynamic> action, ThemeData theme) {
    final type = action['type'] as String? ?? 'Unknown';
    final cfg = action['config'] as Map<String, dynamic>? ?? action;
    final configEntries = cfg.entries
        .where((e) => e.key != 'type')
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(_actionIcon(type), color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _actionLabel(type),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            if (configEntries.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...configEntries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          e.key,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${e.value}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _actionLabel(String type) {
    return switch (type) {
      'create_task' => 'Create Task',
      'create_record' => 'Create Record',
      'send_notification' => 'Send Notification',
      'move_stage' => 'Move Stage',
      'assign_owner' => 'Assign Owner',
      'add_tag' => 'Add Tag',
      'update_field' => 'Update Field',
      _ => type,
    };
  }

  IconData _actionIcon(String type) {
    return switch (type) {
      'create_task' => Icons.task_alt,
      'create_record' => Icons.add_box_outlined,
      'send_notification' => Icons.notifications_outlined,
      'move_stage' => Icons.swap_horiz,
      'assign_owner' => Icons.person_add_outlined,
      'add_tag' => Icons.label_outline,
      'update_field' => Icons.edit_outlined,
      _ => Icons.bolt_outlined,
    };
  }

  void _openEditor(BuildContext context, AutomationRule rule) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<AutomationBloc>(),
          child: AutomationBuilderPage(existingRule: rule),
        ),
      ),
    ).then((_) => _loadRule());
  }

  void _duplicateRule(BuildContext context, AutomationRule rule) {
    final now = DateTime.now();
    final copy = AutomationRule(
      id: '',
      name: '${rule.name} (copy)',
      description: rule.description,
      isActive: false,
      triggerType: rule.triggerType,
      triggerConditions: rule.triggerConditions,
      actions: rule.actions,
      priority: rule.priority,
      createdBy: '',
      createdAt: now,
      updatedAt: now,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<AutomationBloc>(),
          child: AutomationBuilderPage(existingRule: copy),
        ),
      ),
    ).then((_) => _loadRule());
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
        case Failure(:final error):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: ${error.message}')),
          );
      }
    });
  }

  Future<void> _dryRun(BuildContext context, String ruleId) async {
    try {
      final result = await getIt<AutomationRepository>().dryRunRule(ruleId);
      if (!context.mounted) return;
      switch (result) {
        case Success(:final data):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dry run: ${data.status.name}'),
              duration: const Duration(seconds: 4),
            ),
          );
        case Failure(:final error):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dry run failed: ${error.message}')),
          );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dry run error: $e')),
        );
      }
    }
  }
}

class _ExecutionLogSection extends StatefulWidget {
  const _ExecutionLogSection({required this.ruleId});
  final String ruleId;

  @override
  State<_ExecutionLogSection> createState() => _ExecutionLogSectionState();
}

class _ExecutionLogSectionState extends State<_ExecutionLogSection> {
  List<Map<String, dynamic>>? _logs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await getIt<Dio>().get<Map<String, dynamic>>(
        '/api/automation/execution-log',
      );
      final list = response.data?['data'] as List<dynamic>?;
      if (mounted) {
        final all = list?.cast<Map<String, dynamic>>() ?? [];
        final filtered = all
            .where((l) => l['rule_id'] == widget.ruleId)
            .toList();
        setState(() { _logs = filtered; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _logs = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_logs == null || _logs!.isEmpty) {
      return Text(
        'No executions yet',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    return Column(
      children: _logs!.take(10).map((log) {
        final status = log['status'] as String? ?? '';
        final ts = log['created_at'] as String? ?? '';
        final errorDetail = log['error_detail'] as String?;
        final icon = switch (status) {
          'success' => Icons.check_circle,
          'dry_run' => Icons.science_outlined,
          'partial_failure' => Icons.warning_amber,
          'failed' => Icons.error_outline,
          _ => Icons.circle_outlined,
        };
        final color = switch (status) {
          'success' => Colors.green,
          'dry_run' => Colors.blue,
          'partial_failure' => Colors.orange,
          'failed' => Colors.red,
          _ => Colors.grey,
        };
        return ExpansionTile(
          leading: Icon(icon, color: color),
          title: Text(status),
          subtitle: Text(ts),
          dense: true,
          tilePadding: EdgeInsets.zero,
          children: [
            if (errorDetail != null && errorDetail.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                  errorDetail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
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
