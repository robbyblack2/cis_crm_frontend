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
    var selectedTrigger = 'stage_change';

    final triggerTypes = ['stage_change', 'new_record', 'field_update'];

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.createRule),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.ruleName),
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: l10n.ruleDescription),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedTrigger,
                  decoration: InputDecoration(labelText: l10n.ruleTriggerType),
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
                  decoration: InputDecoration(labelText: l10n.rulePriority),
                  keyboardType: TextInputType.number,
                ),
              ],
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
                final now = DateTime.now();
                final rule = AutomationRule(
                  id: '',
                  name: name,
                  description: descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                  isActive: true,
                  triggerType: selectedTrigger,
                  priority: int.tryParse(priorityController.text.trim()) ?? 0,
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
