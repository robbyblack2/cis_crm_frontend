import 'package:cis_crm/features/calendar/domain/entities/calendar_event.dart';
import 'package:flutter/material.dart';

class EventDetailPage extends StatelessWidget {
  const EventDetailPage({required this.event, super.key});

  final CalendarEvent event;

  String _formatDateTime(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(event.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          _DetailRow(
            icon: Icons.access_time,
            label: 'Start',
            value: _formatDateTime(event.start),
          ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.access_time_filled,
            label: 'End',
            value: _formatDateTime(event.end),
          ),
          if (event.location != null) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.location_on,
              label: 'Location',
              value: event.location!,
            ),
          ],
          if (event.meetingLink != null) ...[
            const SizedBox(height: 8),
            _MeetingLinkRow(link: event.meetingLink!),
          ],
          if (event.linkedRecordId != null) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.link,
              label: 'Linked Record',
              value: event.linkedRecordId!,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}

class _MeetingLinkRow extends StatelessWidget {
  const _MeetingLinkRow({required this.link});

  final String link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.videocam,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meeting Link',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              InkWell(
                onTap: () {
                  // TODO(feature): Launch URL with url_launcher.
                },
                child: Text(
                  link,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
