import 'package:cis_crm/features/automation/domain/entities/automation_rule.dart';
import 'package:cis_crm/features/automation/presentation/bloc/automation_bloc.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Full-page multi-step automation builder.
/// Used for both creating new rules and editing existing ones.
class AutomationBuilderPage extends StatefulWidget {
  const AutomationBuilderPage({this.existingRule, super.key});

  /// If non-null, the builder opens in edit mode pre-filled with this rule.
  final AutomationRule? existingRule;

  bool get isEditing => existingRule != null;

  @override
  State<AutomationBuilderPage> createState() => _AutomationBuilderPageState();
}

class _AutomationBuilderPageState extends State<AutomationBuilderPage> {
  int _currentStep = 0;

  // ── Step 1: Trigger ──
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _selectedTrigger;

  // ── Step 2: Conditions ──
  String _conditionOperator = 'All';
  final List<_ConditionRow> _conditions = [];

  // ── Step 3: Actions ──
  final List<_ActionRow> _actions = [];

  // ── Step 4: Review ──
  late int _priority;
  late bool _isActive;

  static const _triggerTypes = [
    'record.stage_changed',
    'record.created',
    'record.updated',
    'contact.created',
    'contact.updated',
    'task.created',
    'task.completed',
    'email.received',
  ];

  static const _actionTypes = [
    'create_task',
    'create_record',
    'move_stage',
    'assign_owner',
    'add_tag',
    'update_field',
    'send_notification',
  ];

  static const _condOps = ['eq', 'neq', 'gt', 'lt', 'contains', 'in'];

  static const _triggerDescriptions = {
    'record.stage_changed': 'When a record moves to a new stage',
    'record.created': 'When a new record is created',
    'record.updated': 'When a record is updated',
    'contact.created': 'When a new contact is added',
    'contact.updated': 'When a contact is modified',
    'task.created': 'When a task is created',
    'task.completed': 'When a task is completed',
    'email.received': 'When an inbound email arrives',
  };

  static const _triggerIcons = {
    'record.stage_changed': Icons.swap_horiz,
    'record.created': Icons.add_box_outlined,
    'record.updated': Icons.edit_outlined,
    'contact.created': Icons.person_add_outlined,
    'contact.updated': Icons.person_outline,
    'task.created': Icons.task_alt,
    'task.completed': Icons.check_circle_outline,
    'email.received': Icons.email_outlined,
  };

  static const _actionDescriptions = {
    'create_task': 'Create a new task',
    'create_record': 'Create a pipeline record',
    'move_stage': 'Move record to another stage',
    'assign_owner': 'Assign an owner',
    'add_tag': 'Add a tag to the record',
    'update_field': 'Update a field value',
    'send_notification': 'Send a notification',
  };

  static const _actionIcons = {
    'create_task': Icons.task_alt,
    'create_record': Icons.add_box_outlined,
    'move_stage': Icons.swap_horiz,
    'assign_owner': Icons.person_add_outlined,
    'add_tag': Icons.label_outline,
    'update_field': Icons.edit_outlined,
    'send_notification': Icons.notifications_outlined,
  };

  @override
  void initState() {
    super.initState();
    final rule = widget.existingRule;
    _nameController = TextEditingController(text: rule?.name ?? '');
    _descriptionController =
        TextEditingController(text: rule?.description ?? '');
    _selectedTrigger = rule?.triggerType ?? _triggerTypes.first;
    _priority = rule?.priority ?? 1;
    _isActive = rule?.isActive ?? true;

    // Pre-fill conditions from existing rule
    if (rule?.triggerConditions != null) {
      final conds = rule!.triggerConditions!;
      if (conds.containsKey('Any')) {
        _conditionOperator = 'Any';
      }
      final list =
          (conds['All'] ?? conds['Any'] ?? conds['conditions']) as List?;
      if (list != null) {
        for (final c in list) {
          if (c is Map<String, dynamic>) {
            _conditions.add(_ConditionRow(
              field: TextEditingController(text: c['field'] as String? ?? ''),
              operator: (c['operator'] ?? c['op']) as String? ?? 'eq',
              value: TextEditingController(text: '${c['value'] ?? ''}'),
            ));
          }
        }
      }
    }

    // Pre-fill actions from existing rule
    if (rule != null && rule.actions.isNotEmpty) {
      for (final a in rule.actions) {
        final type = a['type'] as String? ?? _actionTypes.first;
        final cfg = a['config'] as Map<String, dynamic>? ?? a;
        _actions.add(_ActionRow(type: type, config: Map<String, dynamic>.from(cfg)));
      }
    }

    // Ensure at least one action row for new rules
    if (_actions.isEmpty) {
      _actions.add(_ActionRow(type: _actionTypes.first));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final c in _conditions) {
      c.field.dispose();
      c.value.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Automation Rule' : 'New Automation Rule'),
      ),
      body: Column(
        children: [
          // ── Step indicator ──
          _StepIndicator(
            currentStep: _currentStep,
            labels: const ['Trigger', 'Conditions', 'Actions', 'Review'],
          ),
          const Divider(height: 1),

          // ── Step content ──
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: switch (_currentStep) {
                0 => _buildTriggerStep(theme, l10n),
                1 => _buildConditionsStep(theme),
                2 => _buildActionsStep(theme),
                3 => _buildReviewStep(theme, l10n),
                _ => const SizedBox.shrink(),
              },
            ),
          ),

          // ── Navigation buttons ──
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    child: const Text('Back'),
                  ),
                const Spacer(),
                if (_currentStep < 3)
                  FilledButton(
                    onPressed: _canAdvance() ? () => setState(() => _currentStep++) : null,
                    child: const Text('Next'),
                  )
                else
                  FilledButton.icon(
                    onPressed: _canSave() ? _save : null,
                    icon: const Icon(Icons.check),
                    label: Text(widget.isEditing ? 'Save Changes' : l10n.create),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Step 1 — Trigger
  // ────────────────────────────────────────────────────────────────

  Widget _buildTriggerStep(ThemeData theme, AppLocalizations l10n) {
    return SingleChildScrollView(
      key: const ValueKey('trigger'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.ruleName,
              border: const OutlineInputBorder(),
            ),
            autofocus: !widget.isEditing,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: l10n.ruleDescription,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),
          Text(
            'Select a trigger',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _triggerTypes.map((type) {
              final selected = _selectedTrigger == type;
              return ChoiceChip(
                avatar: Icon(
                  _triggerIcons[type] ?? Icons.bolt_outlined,
                  size: 18,
                  color: selected ? theme.colorScheme.onPrimary : null,
                ),
                label: Text(_displayTriggerType(type)),
                selected: selected,
                onSelected: (_) => setState(() => _selectedTrigger = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _triggerDescriptions[_selectedTrigger] ?? '',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Step 2 — Conditions
  // ────────────────────────────────────────────────────────────────

  Widget _buildConditionsStep(ThemeData theme) {
    return SingleChildScrollView(
      key: const ValueKey('conditions'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conditions',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Leave empty to trigger on all events of this type.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'All', label: Text('All must match')),
              ButtonSegment(value: 'Any', label: Text('Any can match')),
            ],
            selected: {_conditionOperator},
            onSelectionChanged: (v) => setState(() => _conditionOperator = v.first),
          ),
          const SizedBox(height: 16),
          ..._conditions.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: c.field,
                        decoration: const InputDecoration(
                          labelText: 'Field',
                          hintText: 'e.g. stage_id',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: DropdownButtonFormField<String>(
                        initialValue: c.operator,
                        decoration: const InputDecoration(
                          labelText: 'Op',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: _condOps
                            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => c.operator = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: c.value,
                        decoration: const InputDecoration(
                          labelText: 'Value',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: 'Remove condition',
                      onPressed: () => setState(() {
                        _conditions[i].field.dispose();
                        _conditions[i].value.dispose();
                        _conditions.removeAt(i);
                      }),
                    ),
                  ],
                ),
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() {
              _conditions.add(_ConditionRow(
                field: TextEditingController(),
                operator: 'eq',
                value: TextEditingController(),
              ));
            }),
            icon: const Icon(Icons.add),
            label: const Text('Add condition'),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Step 3 — Actions
  // ────────────────────────────────────────────────────────────────

  Widget _buildActionsStep(ThemeData theme) {
    return SingleChildScrollView(
      key: const ValueKey('actions'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Define what happens when the trigger fires.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _actions.length,
            onReorder: (oldIdx, newIdx) {
              setState(() {
                final adjustedIdx = newIdx > oldIdx ? newIdx - 1 : newIdx;
                final item = _actions.removeAt(oldIdx);
                _actions.insert(adjustedIdx, item);
              });
            },
            itemBuilder: (context, i) {
              final a = _actions[i];
              return _ActionCard(
                key: ValueKey('action_$i'),
                action: a,
                actionTypes: _actionTypes,
                actionIcons: _actionIcons,
                actionDescriptions: _actionDescriptions,
                onTypeChanged: (type) => setState(() => a.type = type),
                onConfigChanged: (cfg) => setState(() => a.config = cfg),
                onDelete: _actions.length > 1
                    ? () => setState(() => _actions.removeAt(i))
                    : null,
              );
            },
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() {
              _actions.add(_ActionRow(type: _actionTypes.first));
            }),
            icon: const Icon(Icons.add),
            label: const Text('Add action'),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Step 4 — Review
  // ────────────────────────────────────────────────────────────────

  Widget _buildReviewStep(ThemeData theme, AppLocalizations l10n) {
    return SingleChildScrollView(
      key: const ValueKey('review'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Activate',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Summary sentence
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'When '),
                    TextSpan(
                      text: _displayTriggerType(_selectedTrigger),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_conditions.isNotEmpty) ...[
                      TextSpan(
                        text: ' and ${_conditionOperator.toLowerCase()} of '
                            '${_conditions.length} condition${_conditions.length == 1 ? '' : 's'} match',
                      ),
                    ],
                    const TextSpan(text: ', then execute '),
                    TextSpan(
                      text: '${_actions.length} action${_actions.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name & description
          _ReviewSection(
            title: 'Name',
            content: _nameController.text.trim(),
            theme: theme,
          ),
          if (_descriptionController.text.trim().isNotEmpty)
            _ReviewSection(
              title: 'Description',
              content: _descriptionController.text.trim(),
              theme: theme,
            ),

          // Trigger
          _ReviewSection(
            title: 'Trigger',
            content: _triggerDescriptions[_selectedTrigger] ?? _selectedTrigger,
            theme: theme,
          ),

          // Conditions
          if (_conditions.isNotEmpty)
            _ReviewSection(
              title: 'Conditions ($_conditionOperator)',
              content: _conditions
                  .map((c) => '${c.field.text} ${c.operator} ${c.value.text}')
                  .join('\n'),
              theme: theme,
            ),

          // Actions
          _ReviewSection(
            title: 'Actions',
            content: _actions
                .map((a) => '${_actionDescriptions[a.type] ?? a.type}: '
                    '${a.config.entries.map((e) => '${e.key}=${e.value}').join(', ')}')
                .join('\n'),
            theme: theme,
          ),

          const SizedBox(height: 16),

          // Priority
          DropdownButtonFormField<int>(
            initialValue: _priority,
            decoration: InputDecoration(
              labelText: l10n.rulePriority,
              border: const OutlineInputBorder(),
            ),
            items: [1, 2, 3, 4, 5]
                .map((p) => DropdownMenuItem(value: p, child: Text('Priority $p')))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _priority = v);
            },
          ),
          const SizedBox(height: 12),

          // Active toggle
          SwitchListTile(
            title: const Text('Active'),
            subtitle: Text(_isActive ? 'Rule will run immediately' : 'Rule is paused'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Validation
  // ────────────────────────────────────────────────────────────────

  bool _canAdvance() {
    return switch (_currentStep) {
      0 => _nameController.text.trim().isNotEmpty,
      1 => true, // conditions are optional
      2 => _actions.isNotEmpty,
      _ => true,
    };
  }

  bool _canSave() => _nameController.text.trim().isNotEmpty && _actions.isNotEmpty;

  // ────────────────────────────────────────────────────────────────
  // Save
  // ────────────────────────────────────────────────────────────────

  void _save() {
    // Build conditions map
    Map<String, dynamic>? triggerConditions;
    if (_conditions.isNotEmpty) {
      triggerConditions = {
        _conditionOperator: _conditions
            .where((c) => c.field.text.trim().isNotEmpty)
            .map((c) => {
                  'field': c.field.text.trim(),
                  'operator': c.operator,
                  'value': c.value.text.trim(),
                })
            .toList(),
      };
    }

    // Build actions list
    final actionsList = _actions.map((a) {
      return <String, dynamic>{
        'type': a.type,
        'config': Map<String, dynamic>.from(a.config),
      };
    }).toList();

    final now = DateTime.now();
    final rule = AutomationRule(
      id: widget.existingRule?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      isActive: _isActive,
      triggerType: _selectedTrigger,
      triggerConditions: triggerConditions,
      actions: actionsList,
      priority: _priority,
      createdBy: widget.existingRule?.createdBy ?? '',
      createdAt: widget.existingRule?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.isEditing) {
      context.read<AutomationBloc>().add(AutomationRuleUpdateRequested(rule: rule));
    } else {
      context.read<AutomationBloc>().add(AutomationRuleCreateRequested(rule: rule));
    }
    Navigator.of(context).pop();
  }

  static String _displayTriggerType(String triggerType) {
    return triggerType
        .replaceAll('_', ' ')
        .replaceAll('.', ' → ')
        .replaceFirstMapped(
          RegExp('^[a-z]'),
          (match) => match.group(0)!.toUpperCase(),
        );
  }
}

// ──────────────────────────────────────────────────────────────────
// Helper data classes
// ──────────────────────────────────────────────────────────────────

class _ConditionRow {
  _ConditionRow({
    required this.field,
    required this.operator,
    required this.value,
  });

  final TextEditingController field;
  String operator;
  final TextEditingController value;
}

class _ActionRow {
  _ActionRow({required this.type, Map<String, dynamic>? config})
      : config = config ?? {};

  String type;
  Map<String, dynamic> config;
}

// ──────────────────────────────────────────────────────────────────
// Step indicator
// ──────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.labels});

  final int currentStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: i <= currentStep
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
            _StepDot(
              index: i,
              label: labels[i],
              isActive: i == currentStep,
              isCompleted: i < currentStep,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  final int index;
  final String label;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive || isCompleted
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color,
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Action card with dynamic config fields
// ──────────────────────────────────────────────────────────────────

class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required super.key,
    required this.action,
    required this.actionTypes,
    required this.actionIcons,
    required this.actionDescriptions,
    required this.onTypeChanged,
    required this.onConfigChanged,
    this.onDelete,
  });

  final _ActionRow action;
  final List<String> actionTypes;
  final Map<String, IconData> actionIcons;
  final Map<String, String> actionDescriptions;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<Map<String, dynamic>> onConfigChanged;
  final VoidCallback? onDelete;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  final _controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant _ActionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.action.type != widget.action.type) {
      _syncControllers();
    }
  }

  void _syncControllers() {
    final fields = _fieldsForType(widget.action.type);
    for (final f in fields) {
      final key = f['key'] as String;
      _controllers.putIfAbsent(
        key,
        () => TextEditingController(text: '${widget.action.config[key] ?? ''}'),
      );
      // Sync existing controller text with config
      if (widget.action.config.containsKey(key)) {
        _controllers[key]!.text = '${widget.action.config[key]}';
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<Map<String, String>> _fieldsForType(String type) {
    return switch (type) {
      'create_task' => [
          {'key': 'title', 'label': 'Task title'},
          {'key': 'priority', 'label': 'Priority (low/medium/high)'},
          {'key': 'due_date_days', 'label': 'Due in N days'},
          {'key': 'description', 'label': 'Description'},
        ],
      'create_record' => [
          {'key': 'title', 'label': 'Record title'},
          {'key': 'pipeline_id', 'label': 'Pipeline ID'},
          {'key': 'stage_id', 'label': 'Stage ID'},
          {'key': 'source', 'label': 'Source (email/manual/sync_rule)'},
        ],
      'move_stage' => [
          {'key': 'stage_id', 'label': 'Stage ID'},
        ],
      'assign_owner' => [
          {'key': 'owner_id', 'label': 'Owner ID'},
        ],
      'add_tag' => [
          {'key': 'tag', 'label': 'Tag name'},
        ],
      'update_field' => [
          {'key': 'field', 'label': 'Field key (dot-path)'},
          {'key': 'value', 'label': 'New value'},
        ],
      'send_notification' => [
          {'key': 'message', 'label': 'Message'},
          {'key': 'channel', 'label': 'Channel (optional)'},
        ],
      _ => [],
    };
  }

  void _updateConfig() {
    final cfg = <String, dynamic>{};
    for (final entry in _controllers.entries) {
      final val = entry.value.text.trim();
      if (val.isNotEmpty) {
        // Try to parse numeric values for due_date_days
        if (entry.key == 'due_date_days') {
          final n = int.tryParse(val);
          if (n != null) {
            cfg[entry.key] = n;
            continue;
          }
        }
        cfg[entry.key] = val;
      }
    }
    widget.onConfigChanged(cfg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fields = _fieldsForType(widget.action.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.actionIcons[widget.action.type] ?? Icons.bolt_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: widget.action.type,
                    decoration: const InputDecoration(
                      labelText: 'Action type',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: widget.actionTypes.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(widget.actionDescriptions[t] ?? t),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        widget.onTypeChanged(v);
                        // Clear old controllers
                        for (final c in _controllers.values) {
                          c.clear();
                        }
                        _updateConfig();
                      }
                    },
                  ),
                ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Remove action',
                    onPressed: widget.onDelete,
                  ),
                const Icon(Icons.drag_handle),
              ],
            ),
            if (fields.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...fields.map((f) {
                final key = f['key']!;
                _controllers.putIfAbsent(key, TextEditingController.new);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _controllers[key],
                    decoration: InputDecoration(
                      labelText: f['label'],
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => _updateConfig(),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Review section widget
// ──────────────────────────────────────────────────────────────────

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.content,
    required this.theme,
  });

  final String title;
  final String content;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(content, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
