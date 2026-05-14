import 'package:flutter/material.dart';

/// Full-screen "couldn't load anything" error.
///
/// Used when an initial fetch returned `Failure` and there is no prior
/// data to keep visible. Pair with a retry callback that dispatches a
/// `XxxRetryRequested` event to the page's bloc.
///
/// The widget never reads any specific bloc — `onRetry` is a plain
/// `VoidCallback`. The call site wires it.
class PageError extends StatelessWidget {
  const PageError({
    required this.title,
    required this.onRetry,
    this.message,
    super.key,
  });

  final String title;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleLarge),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
