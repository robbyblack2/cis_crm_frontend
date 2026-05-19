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

    final triggerTypes = [
      'record.stage_changed',
      'record.created',
      'task.completed',
    ];
    final actionTypes = [
      'create_task',
      'send_email',
      'move_stage',
      'assign_user',
      'add_tag',
      'update_field',
      'send_webhook',
    ];
    final condOps = ['eq', 'neq', 'gt', 'lt', 'contains', 'in'];

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.createRule),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
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
                        'send_email' => 'Template ID',
                        'move_stage' => 'Stage ID',
                        'assign_user' => 'User ID or "round_robin"',
                        'add_tag' => 'Tag name',
                        'update_field' => 'Field key',
                        'send_webhook' => 'URL',
                        _ => 'Value',
                      },
                    ),
                  ),
                  if (selectedActionType == 'create_task' ||
                      selectedActionType == 'update_field' ||
                      selectedActionType == 'send_webhook') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: actionValueController,
                      decoration: InputDecoration(
                        labelText: switch (selectedActionType) {
                          'create_task' => 'Priority (low/medium/high)',
                          'update_field' => 'New value',
                          'send_webhook' => 'Method (GET/POST)',
                          _ => 'Extra',
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                // Build conditions
                Map<String, dynamic>? triggerConditions;
                if (condFieldController.text.trim().isNotEmpty) {
                  triggerConditions = {
                    'operator': 'AND',
                    'conditions': [
                      {
                        'field': condFieldController.text.trim(),
                        'op': condOperator,
                        'value': condValueController.text.trim(),
                      },
                    ],
                  };
                }

                // Build action
                final actionConfig = <String, dynamic>{
                  'type': selectedActionType,
                };
                final mainVal = actionTitleController.text.trim();
                final extraVal = actionValueController.text.trim();

                switch (selectedActionType) {
                  case 'create_task':
                    actionConfig['title'] = mainVal;
                    if (extraVal.isNotEmpty) {
                      actionConfig['priority'] = extraVal;
                    }
                  case 'send_email':
                    actionConfig['template_id'] = mainVal;
                  case 'move_stage':
                    actionConfig['stage_id'] = mainVal;
                  case 'assign_user':
                    actionConfig['user_id'] = mainVal;
                  case 'add_tag':
                    actionConfig['tag'] = mainVal;
                  case 'update_field':
                    actionConfig['field_key'] = mainVal;
                    actionConfig['value'] = extraVal;
                  case 'send_webhook':
                    actionConfig['url'] = mainVal;
                    actionConfig['method'] =
                        extraVal.isNotEmpty ? extraVal : 'POST';
                }

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
      ),
    );
  }
}
