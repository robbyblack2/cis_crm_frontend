import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/automation/domain/entities/automation_rule.dart';
import 'package:cis_crm/features/automation/domain/repositories/automation_repository.dart';
import 'package:cis_crm/features/automation/presentation/bloc/automation_bloc.dart';
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
    // Backend doesn't support GET /api/automation/rules/:id (405)
    // Fetch all rules and find by ID
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
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => _showEditSheet(context, rule),
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

  Widget _buildConditions(Map<String, dynamic> conditions) {
    // Support both All/Any and AND/OR formats
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
        Text('Match: $operator'),
        const SizedBox(height: 8),
        for (final cond in condList)
          if (cond is Map<String, dynamic>)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${cond['field']} ${cond['operator'] ?? cond['op']} ${cond['value']}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
      ],
    );
  }

  String _actionSummary(Map<String, dynamic> action) {
    final type = action['type'] as String?;
    // Config may be nested or top-level
    final cfg = action['config'] as Map<String, dynamic>? ?? action;
    return switch (type) {
      'create_task' => () {
          final parts = <String>['Title: ${cfg['title'] ?? '—'}'];
          if (cfg['priority'] != null) parts.add('Priority: ${cfg['priority']}');
          if (cfg['due_date_days'] != null) {
            parts.add('Due in ${cfg['due_date_days']}d');
          }
          return parts.join(', ');
        }(),
      'create_record' =>
        'Title: ${cfg['title'] ?? '—'}, Pipeline: ${cfg['pipeline_id'] ?? '—'}, Source: ${cfg['source'] ?? '—'}',
      'send_notification' =>
        'Message: ${cfg['message'] ?? cfg['template_id'] ?? '—'}',
      'move_stage' => 'Stage: ${cfg['stage_id'] ?? '—'}',
      'assign_owner' => 'Owner: ${cfg['owner_id'] ?? cfg['user_id'] ?? '—'}',
      'add_tag' => 'Tag: ${cfg['tag'] ?? '—'}',
      'update_field' =>
        '${cfg['field'] ?? cfg['field_key'] ?? '—'} = ${cfg['value'] ?? '—'}',
      _ => action.toString(),
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

  void _showEditSheet(BuildContext context, AutomationRule rule) {
    final nameCtrl = TextEditingController(text: rule.name);
    final descCtrl = TextEditingController(text: rule.description ?? '');
    var priority = rule.priority;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Rule',
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Rule Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: [1, 2, 3, 4, 5]
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text('Priority $p'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setSheetState(() => priority = v);
                    }
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final updated = AutomationRule(
                      id: rule.id,
                      name: name,
                      description: descCtrl.text.trim().isNotEmpty
                          ? descCtrl.text.trim()
                          : null,
                      isActive: rule.isActive,
                      triggerType: rule.triggerType,
                      triggerConditions: rule.triggerConditions,
                      actions: rule.actions,
                      priority: priority,
                      createdBy: rule.createdBy,
                      createdAt: rule.createdAt,
                      updatedAt: DateTime.now(),
                    );
                    context
                        .read<AutomationBloc>()
                        .add(AutomationRuleUpdateRequested(rule: updated));
                    Navigator.pop(ctx);
                    // Reload the detail
                    _loadRule();
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        // Filter logs for this rule
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
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: color),
          title: Text(status),
          subtitle: Text(ts),
          dense: true,
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
