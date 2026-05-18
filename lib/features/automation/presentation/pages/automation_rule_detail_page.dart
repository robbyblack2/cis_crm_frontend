import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class AutomationRuleDetailPage extends StatelessWidget {
  const AutomationRuleDetailPage({required this.ruleId, super.key});

  final String ruleId;

  @override
  Widget build(BuildContext context) {
    // NOTE: The detail view is a placeholder; the bloc no longer has a
    // detail-load event.  Just show a simple scaffold.
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.ruleDetail)),
      body: Center(
        child: Text(
          AppLocalizations.of(context)!.ruleDetailComingSoon(ruleId),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
