import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class PageLoading extends StatelessWidget {
  const PageLoading({super.key, this.label});

  /// Optional override label. Falls back to [AppLocalizations.loading].
  final String? label;

  @override
  Widget build(BuildContext context) {
    final displayLabel = label ?? AppLocalizations.of(context)?.loading;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (displayLabel != null) ...[
              const SizedBox(height: 16),
              Text(
                displayLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
