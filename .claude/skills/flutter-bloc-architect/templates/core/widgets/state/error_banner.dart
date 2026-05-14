import 'package:flutter/material.dart';

/// Persistent dismissable error banner.
///
/// Used for "background refresh failed but cached data is still valid"
/// — the user has something to look at, but should know the data may
/// be stale. Show via [show]; dismiss via [hide] or the user tapping
/// the close action.
abstract final class ErrorBanner {
  static void show(BuildContext context, {required String message}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      MaterialBanner(
        content: Text(message),
        leading: Icon(Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error),
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
