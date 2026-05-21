import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/features/calendar/domain/entities/calendar_event.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.eventDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            tooltip: 'Delete event',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Event?'),
                  content: const Text('This will remove the event.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) return;
              try {
                await getIt<Dio>().delete<void>(
                  '/api/calendar/events/${event.id}',
                );
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
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
          if (event.hasMeeting) ...[
            const SizedBox(height: 16),
            _JoinMeetingCard(
              meetingUrl: event.meetingLink!,
              provider: event.conferenceProvider,
            ),
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

class _JoinMeetingCard extends StatelessWidget {
  const _JoinMeetingCard({
    required this.meetingUrl,
    this.provider,
  });

  final String meetingUrl;
  final String? provider;

  IconData get _providerIcon {
    final p = (provider ?? '').toLowerCase();
    if (p.contains('zoom')) return Icons.videocam;
    if (p.contains('teams')) return Icons.groups;
    return Icons.video_call; // Google Meet default
  }

  Color _providerColor(ColorScheme cs) {
    final p = (provider ?? '').toLowerCase();
    if (p.contains('zoom')) return const Color(0xFF2D8CFF);
    if (p.contains('teams')) return const Color(0xFF6264A7);
    return const Color(0xFF1A73E8); // Google Meet blue
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _providerColor(cs);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      color: color.withValues(alpha: 0.05),
      child: InkWell(
        onTap: () => _launchUrl(meetingUrl),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(_providerIcon, size: 28, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join ${provider ?? 'Meeting'}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      meetingUrl,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
