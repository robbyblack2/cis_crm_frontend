import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

abstract final class ErrorSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: onRetry == null
              ? null
              : SnackBarAction(label: l10n.retry, onPressed: onRetry),
        ),
      );
  }
}
