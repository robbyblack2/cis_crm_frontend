import 'package:cis_crm/features/activity/domain/entities/timeline_entry.dart';
import 'package:flutter/material.dart';

class TimelineWidget extends StatelessWidget {
  const TimelineWidget({required this.entries, super.key});

  final List<TimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('No timeline entries.'));
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          title: Text(entry.summary),
          subtitle: Text(entry.eventType),
          trailing: Text(entry.createdAt.toIso8601String()),
        );
      },
    );
  }
}
