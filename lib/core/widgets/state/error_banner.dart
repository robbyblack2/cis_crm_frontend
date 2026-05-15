import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

abstract final class ErrorBanner {
  static void show(BuildContext context, {required String message}) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..clearMaterialBanners()
      ..showMaterialBanner(
        MaterialBanner(
          content: Text(message),
          leading: Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          actions: [
            TextButton(
              onPressed: () => hide(context),
              child: Text(l10n.dismiss),
            ),
          ],
        ),
      );
  }

  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).clearMaterialBanners();
  }
}
