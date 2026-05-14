import 'package:flutter/material.dart';

abstract final class ErrorBanner {
  static void show(BuildContext context, {required String message}) {
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
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).clearMaterialBanners();
  }
}
