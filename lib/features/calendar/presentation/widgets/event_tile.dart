import 'package:cis_crm/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter/material.dart';

class EventTile extends StatelessWidget {
  const EventTile({
    required this.event,
    this.onTap,
    super.key,
  });

  final CalendarEvent event;
  final VoidCallback? onTap;

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(event.title, style: theme.textTheme.bodyLarge),
      subtitle: Text(
        [
          '${_formatTime(event.start)} \u2013 ${_formatTime(event.end)}',
          if (event.location != null) event.location,
        ].join(' \u2022 '),
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}
