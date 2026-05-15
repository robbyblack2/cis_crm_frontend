import 'package:cis_crm/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter/material.dart';

class EventDetailPage extends StatelessWidget {
  const EventDetailPage({required this.event, super.key});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Start: ${event.start}'),
            Text('End: ${event.end}'),
            if (event.location != null) Text('Location: ${event.location}'),
            if (event.meetingLink != null)
              Text('Meeting Link: ${event.meetingLink}'),
          ],
        ),
      ),
    );
  }
}
