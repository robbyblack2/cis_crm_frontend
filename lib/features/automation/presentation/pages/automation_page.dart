import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/automation/presentation/bloc/automation_bloc.dart';
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
        onPressed: () {
          // TODO(automation): Navigate to create rule page.
        },
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
                    onTap: () {
                      // TODO(automation): Navigate to rule detail.
                    },
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
}
