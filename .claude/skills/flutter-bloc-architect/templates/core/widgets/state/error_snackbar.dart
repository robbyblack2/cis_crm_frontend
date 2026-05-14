import 'package:flutter/material.dart';

/// One-shot transient error toast.
///
/// Used for "discrete action failed, page state unchanged" — e.g.,
/// "Couldn't add to cart". Triggered from a page-level `BlocListener`
/// reacting to a transient state.
abstract final class ErrorSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    final messenger = ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: onRetry == null
            ? null
            : SnackBarAction(label: 'Retry', onPressed: onRetry),
      ),
    );
  }
}
