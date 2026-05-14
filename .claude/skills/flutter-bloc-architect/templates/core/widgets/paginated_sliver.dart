import 'package:flutter/material.dart';

/// A sliver that auto-fires `onLoadMore` when the user scrolls within
/// [triggerThreshold] items of the end. Includes a footer for in-progress
/// loads and a retry tile for errors that keep prior pages visible.
///
/// Pair with a feature bloc whose state hierarchy carries the items list
/// (e.g., `FeedLoaded`, `FeedLoadingMore`, `FeedError`). The page widget
/// passes the current items + pagination flags into this sliver.
class PaginatedSliver<T> extends StatelessWidget {
  const PaginatedSliver({
    required this.items,
    required this.itemBuilder,
    required this.hasMore,
    required this.isLoadingMore,
    required this.hasError,
    required this.onLoadMore,
    required this.onRetry,
    this.triggerThreshold = 3,
    super.key,
  });

  final List<T> items;
  final Widget Function(BuildContext, T item, int index) itemBuilder;
  final bool hasMore;
  final bool isLoadingMore;
  final bool hasError;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;
  final int triggerThreshold;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == items.length) return _footer(context);
        if (hasMore &&
            !isLoadingMore &&
            !hasError &&
            index >= items.length - triggerThreshold) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
        }
        return itemBuilder(context, items[index], index);
      },
    );
  }

  Widget _footer(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (hasError) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text("Couldn't load more — tap to retry"),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
