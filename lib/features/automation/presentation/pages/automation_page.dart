import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/automation/domain/entities/automation_rule.dart';
import 'package:cis_crm/features/automation/presentation/bloc/automation_bloc.dart';
import 'package:cis_crm/features/automation/presentation/pages/automation_builder_page.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.automationTitle)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'automation_fab',
        tooltip: l10n.createRule,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: context.read<AutomationBloc>(),
              child: const AutomationBuilderPage(),
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<AutomationBloc, AutomationState>(
        builder: (context, state) {
          return switch (state) {
            AutomationInitial() || AutomationLoading() => const PageLoading(),
            AutomationLoaded(:final rules) when rules.isEmpty =>
              EmptyState(
                icon: Icons.bolt_outlined,
                title: l10n.automationEmpty,
                message: l10n.automationEmptyMessage,
              ),
            AutomationLoaded(:final rules) => _RulesList(rules: rules),
            AutomationError(:final message) => PageError(
                title: l10n.failedToLoadRules,
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

class _RulesList extends StatelessWidget {
  const _RulesList({required this.rules});

  final List<AutomationRule> rules;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: rules.length,
      itemBuilder: (context, index) {
        final rule = rules[index];
        return AutomationRuleTile(
          rule: rule,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider.value(
                value: context.read<AutomationBloc>(),
                child: AutomationRuleDetailPage(ruleId: rule.id),
              ),
            ),
          ),
          onToggle: (_) {
            context.read<AutomationBloc>().add(
                  AutomationRuleToggleRequested(ruleId: rule.id),
                );
          },
        );
      },
    );
  }
}
