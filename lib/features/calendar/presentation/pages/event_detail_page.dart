import 'package:cis_crm/features/calendar/domain/entities/calendar_event.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.eventDetails)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(event.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          _DetailRow(
            icon: Icons.access_time,
            label: AppLocalizations.of(context)!.start,
            value: _formatDateTime(event.start),
          ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.access_time_filled,
            label: AppLocalizations.of(context)!.end,
            value: _formatDateTime(event.end),
          ),
          if (event.location != null) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.location_on,
              label: AppLocalizations.of(context)!.eventLocation,
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
              label: AppLocalizations.of(context)!.linkedRecord,
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
                AppLocalizations.of(context)!.eventMeetingLink,
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
