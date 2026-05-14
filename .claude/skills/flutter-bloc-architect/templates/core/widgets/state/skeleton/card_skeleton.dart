import 'package:flutter/material.dart';

import 'shimmer.dart';

/// Single-card placeholder. Use as a single-screen first-load indicator
/// for record-shaped pages.
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key, this.height = 180});

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: SizedBox(
          height: height,
          child: Container(color: theme.colorScheme.surfaceContainerHighest),
        ),
      ),
    );
  }
}
