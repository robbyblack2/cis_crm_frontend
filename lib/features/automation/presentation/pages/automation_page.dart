import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/automation/domain/entities/automation_rule.dart';
import 'package:cis_crm/features/automation/presentation/bloc/automation_bloc.dart';
import 'package:cis_crm/features/automation/presentation/pages/automation_rule_detail_page.dart';
import 'package:cis_crm/features/automation/presentation/widgets/automation_rule_tile.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AutomationPage extends StatelessWidget {
  const AutomationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AutomationBloc>()..add(const AutomationRulesLoadRequested()),
      child: const _AutomationView(),
    );
  }
}

class _AutomationView extends StatelessWidget {
  const _AutomationView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.automationTitle)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'automation_fab',
        tooltip: AppLocalizations.of(context)!.createRule,
        onPressed: () => _showCreateRuleDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<AutomationBloc, AutomationState>(
        builder: (context, state) {
          return switch (state) {
            AutomationInitial() || AutomationLoading() => const PageLoading(),
            AutomationLoaded(:final rules) when rules.isEmpty =>
              EmptyState(
                icon: Icons.bolt_outlined,
                title: AppLocalizations.of(context)!.automationEmpty,
                message: AppLocalizations.of(context)!.automationEmptyMessage,
              ),
            AutomationLoaded(:final rules) => ListView.builder(
                itemCount: rules.length,
                itemBuilder: (context, index) {
                  final rule = rules[index];
                  return AutomationRuleTile(
                    rule: rule,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            AutomationRuleDetailPage(ruleId: rule.id),
                      ),
                    ),
                    onToggle: (_) {
                      context.read<AutomationBloc>().add(
                            AutomationRuleToggleRequested(ruleId: rule.id),
                          );
                    },
                  );
                },
              ),
            AutomationError(:final message) => PageError(
                title: AppLocalizations.of(context)!.failedToLoadRules,
                message: message,
                onRetry: () {
                  context
                      .read<AutomationBloc>()
                      .add(const AutomationRulesLoadRequested());
                },
              ),
          };
        },
      ),
    );
  }

  void _showCreateRuleDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priorityController = TextEditingController(text: '0');
    var selectedTrigger = 'record.stage_changed';
    var selectedActionType = 'create_task';

    // Condition fields
    final condFieldController = TextEditingController();
    final condValueController = TextEditingController();
    var condOperator = 'eq';

    // Action config fields
    final actionTitleController = TextEditingController();
    final actionValueController = TextEditingController();
    final actionExtra1Controller = TextEditingController();
    final actionExtra2Controller = TextEditingController();

    final triggerTypes = [
      'record.stage_changed',
      'record.created',
      'record.updated',
      'contact.created',
      'contact.updated',
      'task.created',
      'task.completed',
      'email.received',
    ];
    final actionTypes = [
      'create_task',
      'create_record',
      'move_stage',
      'assign_owner',
      'add_tag',
      'update_field',
      'send_notification',
    ];
    final condOps = ['eq', 'neq', 'gt', 'lt', 'contains', 'in'];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) =>
                SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Basic info ──
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: l10n.ruleName),
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration:
                        InputDecoration(labelText: l10n.ruleDescription),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedTrigger,
                    decoration:
                        InputDecoration(labelText: l10n.ruleTriggerType),
                    items: triggerTypes
                        .map(
                          (t) => DropdownMenuItem(value: t, child: Text(t)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedTrigger = v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priorityController,
                    decoration:
                        InputDecoration(labelText: l10n.rulePriority),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // ── Condition (optional) ──
                  Text(
                    'Condition (optional)',
                    style: Theme.of(dialogContext).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: condFieldController,
                          decoration: const InputDecoration(
                            labelText: 'Field',
                            hintText: 'e.g. stage_id',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: DropdownButtonFormField<String>(
                          value: condOperator,
                          decoration: const InputDecoration(
                            labelText: 'Op',
                            isDense: true,
                          ),
                          items: condOps
                              .map(
                                (o) => DropdownMenuItem(
                                  value: o,
                                  child: Text(o),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => condOperator = v);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: condValueController,
                          decoration: const InputDecoration(
                            labelText: 'Value',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Action ──
                  Text(
                    'Action',
                    style: Theme.of(dialogContext).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedActionType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: actionTypes
                        .map(
                          (t) => DropdownMenuItem(value: t, child: Text(t)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedActionType = v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: actionTitleController,
                    decoration: InputDecoration(
                      labelText: switch (selectedActionType) {
                        'create_task' => 'Task title',
                        'create_record' => 'Record title',
                        'move_stage' => 'Stage ID',
                        'assign_owner' => 'Owner ID',
                        'add_tag' => 'Tag name',
                        'update_field' => 'Field key',
                        'send_notification' => 'Message',
                        _ => 'Value',
                      },
                    ),
                  ),
                  if (selectedActionType == 'create_task') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: actionValueController,
                      decoration: const InputDecoration(
                        labelText: 'Priority (low/medium/high)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: actionExtra1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Due date days (e.g. 3)',
                        hintText: 'Creates task due in N days',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: actionExtra2Controller,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                      maxLines: 2,
                    ),
                  ],
                  if (selectedActionType == 'create_record') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: actionValueController,
                      decoration: const InputDecoration(
                        labelText: 'Pipeline ID',
                        hintText: 'Target pipeline',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: actionExtra1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Stage ID',
                        hintText: 'Target stage',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: actionExtra2Controller,
                      decoration: const InputDecoration(
                        labelText: 'Source (email/manual/sync_rule)',
                      ),
                    ),
                  ],
                  if (selectedActionType == 'update_field') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: actionValueController,
                      decoration: const InputDecoration(
                        labelText: 'New value',
                      ),
                    ),
                  ],
                  if (selectedActionType == 'send_notification') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: actionValueController,
                      decoration: const InputDecoration(
                        labelText: 'Channel (optional)',
                      ),
                    ),
                  ],
                  // ── Buttons ──
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                // Build conditions
                Map<String, dynamic>? triggerConditions;
                if (condFieldController.text.trim().isNotEmpty) {
                  triggerConditions = {
                    'All': [
                      {
                        'field': condFieldController.text.trim(),
                        'operator': condOperator,
                        'value': condValueController.text.trim(),
                      },
                    ],
                  };
                }

                // Build action with config nested
                final mainVal = actionTitleController.text.trim();
                final extraVal = actionValueController.text.trim();
                final config = <String, dynamic>{};

                final extra1 = actionExtra1Controller.text.trim();
                final extra2 = actionExtra2Controller.text.trim();

                switch (selectedActionType) {
                  case 'create_task':
                    config['title'] = mainVal;
                    if (extraVal.isNotEmpty) {
                      config['priority'] = extraVal;
                    }
                    config['parent_type'] = 'record';
                    if (extra1.isNotEmpty) {
                      final days = int.tryParse(extra1);
                      if (days != null) config['due_date_days'] = days;
                    }
                    if (extra2.isNotEmpty) {
                      config['description'] = extra2;
                    }
                  case 'create_record':
                    config['title'] = mainVal;
                    if (extraVal.isNotEmpty) {
                      config['pipeline_id'] = extraVal;
                    }
                    if (extra1.isNotEmpty) {
                      config['stage_id'] = extra1;
                    }
                    if (extra2.isNotEmpty) {
                      config['source'] = extra2;
                    }
                  case 'send_notification':
                    config['message'] = mainVal;
                    if (extraVal.isNotEmpty) {
                      config['channel'] = extraVal;
                    }
                  case 'move_stage':
                    config['stage_id'] = mainVal;
                  case 'assign_owner':
                    config['owner_id'] = mainVal;
                  case 'add_tag':
                    config['tag'] = mainVal;
                  case 'update_field':
                    config['field'] = mainVal;
                    config['value'] = extraVal;
                }
                final actionConfig = <String, dynamic>{
                  'type': selectedActionType,
                  'config': config,
                };

                final now = DateTime.now();
                final rule = AutomationRule(
                  id: '',
                  name: name,
                  description:
                      descriptionController.text.trim().isNotEmpty
                          ? descriptionController.text.trim()
                          : null,
                  isActive: true,
                  triggerType: selectedTrigger,
                  triggerConditions: triggerConditions,
                  actions: [actionConfig],
                  priority:
                      int.tryParse(priorityController.text.trim()) ?? 0,
                  createdBy: '',
                  createdAt: now,
                  updatedAt: now,
                );
                context.read<AutomationBloc>().add(
                      AutomationRuleCreateRequested(rule: rule),
                    );
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(l10n.create),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
