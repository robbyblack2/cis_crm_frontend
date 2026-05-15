import 'package:cis_crm/features/activity/domain/entities/timeline_entry.dart';
import 'package:flutter/material.dart';

class TimelineWidget extends StatelessWidget {
  const TimelineWidget({required this.entries, super.key});

  final List<TimelineEntry> entries;

  IconData _iconForType(String eventType) {
    return switch (eventType) {
      'call' => Icons.phone,
      'task' => Icons.check_circle_outline,
      'email' => Icons.email,
      'meeting' => Icons.groups,
      'note' => Icons.note,
      _ => Icons.circle,
    };
  }

  Color _colorForType(String eventType, ColorScheme scheme) {
    return switch (eventType) {
      'call' => Colors.blue,
      'task' => Colors.green,
      'email' => Colors.orange,
      'meeting' => Colors.purple,
      'note' => scheme.onSurfaceVariant,
      _ => scheme.onSurfaceVariant,
    };
  }

  String _formatTimestamp(DateTime timestamp) {
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '${timestamp.year}-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No timeline entries',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isLast = index == entries.length - 1;
        final color = _colorForType(entry.eventType, theme.colorScheme);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Timeline gutter ──
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _iconForType(entry.eventType),
                        size: 16,
                        color: color,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // ── Content ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.summary,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimestamp(entry.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
