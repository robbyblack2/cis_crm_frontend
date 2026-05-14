import 'package:flutter/material.dart';

abstract final class ErrorSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: onRetry == null
              ? null
              : SnackBarAction(label: 'Retry', onPressed: onRetry),
        ),
      );
  }
}
