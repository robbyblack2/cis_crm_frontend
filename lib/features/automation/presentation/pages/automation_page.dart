import 'package:cis_crm/features/automation/presentation/bloc/automation_bloc.dart';
import 'package:cis_crm/features/automation/presentation/widgets/automation_rule_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AutomationPage extends StatelessWidget {
  const AutomationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Automation Rules')),
      body: BlocBuilder<AutomationBloc, AutomationState>(
        builder: (context, state) {
          return switch (state) {
            AutomationInitial() => const Center(
                child: Text('Load automation rules to get started.'),
              ),
            AutomationLoading() =>
              const Center(child: CircularProgressIndicator()),
            AutomationLoaded(:final rules) => ListView.builder(
                itemCount: rules.length,
                itemBuilder: (context, index) =>
                    AutomationRuleTile(rule: rules[index]),
              ),
            AutomationError(:final message) => Center(
                child: Text(message),
              ),
          };
        },
      ),
    );
  }
}
