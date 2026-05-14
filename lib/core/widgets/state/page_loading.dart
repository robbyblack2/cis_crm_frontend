import 'package:flutter/material.dart';

class PageLoading extends StatelessWidget {
  const PageLoading({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (label != null) ...[
              const SizedBox(height: 16),
              Text(label!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
