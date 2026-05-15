import 'package:cis_crm/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter/material.dart';

class EventTile extends StatelessWidget {
  const EventTile({required this.event, super.key});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(event.title),
      subtitle: Text(
        '${event.start.toLocal()} - ${event.end.toLocal()}',
      ),
      trailing: event.location != null ? const Icon(Icons.location_on) : null,
    );
  }
}
