import 'package:flutter/material.dart';

/// Shows a confirmation dialog and returns `true` if the user confirms,
/// or `null` if dismissed.
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  String? message,
  String confirmLabel = 'Delete',
  bool isDestructive = false,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message != null ? Text(message) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
