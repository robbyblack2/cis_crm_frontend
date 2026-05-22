import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:cis_crm/features/activity/presentation/widgets/activities_calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Full-page activity detail showing all fields for any activity type.
class ActivityDetailPage extends StatelessWidget {
  const ActivityDetailPage({
    super.key,
    required this.activity,
    this.onStatusChanged,
    this.onDeleted,
  });

  final Activity activity;
  final VoidCallback? onStatusChanged;
  final VoidCallback? onDeleted;

  static final _dateFmt = DateFormat('EEEE, MMMM d, yyyy');
  static final _dateTimeFmt = DateFormat('EEEE, MMMM d, yyyy · h:mm a');
  static final _timeFmt = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = ActivityColors.forType(activity.activityType);
    final typeLabel = activity.activityType.name[0].toUpperCase() +
        activity.activityType.name.substring(1);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(typeLabel),
        actions: [
          if (onDeleted != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context, cs),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 60, child: _buildMainColumn(theme, cs, color)),
                VerticalDivider(width: 1, color: cs.outlineVariant),
                Expanded(flex: 40, child: _buildSidebar(theme, cs, color)),
              ],
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme, cs, color),
                const SizedBox(height: 24),
                _buildAllDetails(theme, cs, color),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Wide layout: main column ──

  Widget _buildMainColumn(ThemeData theme, ColorScheme cs, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, cs, color),
          const SizedBox(height: 24),
          // Description section
          if (activity.description != null &&
              activity.description!.isNotEmpty) ...[
            _sectionTitle(theme, cs, 'Description'),
            const SizedBox(height: 8),
            Text(activity.description!, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
          ],
          // Meeting attendees
          if (activity.isMeeting &&
              activity.attendees != null &&
              activity.attendees!.isNotEmpty) ...[
            _sectionTitle(theme, cs, 'Attendees'),
            const SizedBox(height: 8),
            ...activity.attendees!.map(
              (a) => _AttendeeRow(attendee: a),
            ),
            const SizedBox(height: 24),
          ],
          // Linked entities
          if (activity.links.isNotEmpty) ...[
            _sectionTitle(theme, cs, 'Linked To'),
            const SizedBox(height: 8),
            ...activity.links.map((link) => ListTile(
                  dense: true,
                  leading: Icon(_entityIcon(link.entityType), size: 20),
                  title: Text(
                    '${link.entityType[0].toUpperCase()}${link.entityType.substring(1)} · ${link.entityId}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  contentPadding: EdgeInsets.zero,
                )),
          ],
        ],
      ),
    );
  }

  // ── Wide layout: sidebar ──

  Widget _buildSidebar(ThemeData theme, ColorScheme cs, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _buildAllDetails(theme, cs, color),
    );
  }

  // ── Header: title, type badge, status ──

  Widget _buildHeader(ThemeData theme, ColorScheme cs, Color color) {
    final typeLabel = activity.activityType.name[0].toUpperCase() +
        activity.activityType.name.substring(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type + status badges row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _badge(color.withValues(alpha: 0.15), color, typeLabel,
                icon: _typeIcon(activity.activityType)),
            _badge(
              activity.isCompleted
                  ? Colors.green.withValues(alpha: 0.15)
                  : cs.primaryContainer,
              activity.isCompleted ? Colors.green : cs.onPrimaryContainer,
              activity.statusName,
              icon: activity.isCompleted
                  ? Icons.check_circle_outline
                  : Icons.radio_button_unchecked,
            ),
            if (activity.subtypeName != null)
              _badge(cs.tertiaryContainer, cs.onTertiaryContainer,
                  activity.subtypeName!),
            if (activity.priority != null &&
                activity.priority != ActivityPriority.none)
              _badge(
                _priorityColor(activity.priority!).withValues(alpha: 0.15),
                _priorityColor(activity.priority!),
                '${activity.priority!.name[0].toUpperCase()}${activity.priority!.name.substring(1)} Priority',
                icon: Icons.flag,
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Title
        Text(
          activity.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── All detail fields ──

  Widget _buildAllDetails(ThemeData theme, ColorScheme cs, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, cs, 'Details'),
        const SizedBox(height: 12),

        // Meeting-specific: date/time
        if (activity.isMeeting) ...[
          if (activity.startTime != null)
            _detailRow(
              theme,
              cs,
              Icons.schedule,
              'Start',
              _dateTimeFmt.format(activity.startTime!.toLocal()),
            ),
          if (activity.endTime != null)
            _detailRow(
              theme,
              cs,
              Icons.schedule,
              'End',
              _dateTimeFmt.format(activity.endTime!.toLocal()),
            ),
          if (activity.startTime != null && activity.endTime != null)
            _detailRow(
              theme,
              cs,
              Icons.timelapse,
              'Duration',
              _formatDuration(
                  activity.endTime!.difference(activity.startTime!)),
            ),
          if (activity.meetingUrl != null &&
              activity.meetingUrl!.isNotEmpty)
            _detailRow(
              theme,
              cs,
              Icons.videocam,
              'Meeting Link',
              activity.meetingUrl!,
              isLink: true,
              onCopy: () => _copyToClipboard(
                  context: null, text: activity.meetingUrl!),
            ),
          if (activity.conferenceProvider != null)
            _detailRow(
              theme,
              cs,
              Icons.video_call,
              'Provider',
              _formatProvider(activity.conferenceProvider!),
            ),
          if (activity.calendarProvider != null)
            _detailRow(
              theme,
              cs,
              Icons.cloud_sync,
              'Calendar',
              '${activity.calendarProvider![0].toUpperCase()}${activity.calendarProvider!.substring(1)} Calendar',
            ),
          if (activity.calendarEventId != null)
            _detailRow(
              theme,
              cs,
              Icons.tag,
              'Event ID',
              activity.calendarEventId!,
            ),
        ],

        // Task/Call-specific: due date/time
        if (!activity.isMeeting) ...[
          if (activity.dueDate != null)
            _detailRow(
              theme,
              cs,
              Icons.event,
              'Due Date',
              _formatDateString(activity.dueDate!),
            ),
          if (activity.dueTime != null)
            _detailRow(
              theme,
              cs,
              Icons.schedule,
              'Due Time',
              _formatTimeString(activity.dueTime!),
            ),
        ],

        // Call-specific fields from data
        if (activity.isCall) ...[
          if (activity.data['direction'] != null)
            _detailRow(
              theme,
              cs,
              activity.data['direction'] == 'inbound'
                  ? Icons.call_received
                  : Icons.call_made,
              'Direction',
              _capitalize(activity.data['direction'] as String),
            ),
          if (activity.data['outcome'] != null)
            _detailRow(
              theme,
              cs,
              Icons.call_end,
              'Outcome',
              _capitalize(activity.data['outcome'] as String),
            ),
          if (activity.data['duration_seconds'] != null)
            _detailRow(
              theme,
              cs,
              Icons.timer,
              'Duration',
              _formatSeconds(activity.data['duration_seconds'] as num),
            ),
        ],

        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        _sectionTitle(theme, cs, 'Metadata'),
        const SizedBox(height: 12),

        if (activity.assigneeId != null)
          _detailRow(theme, cs, Icons.person, 'Assignee',
              activity.assigneeId!),
        if (activity.createdBy != null)
          _detailRow(theme, cs, Icons.person_outline, 'Created By',
              activity.createdBy!),
        _detailRow(
          theme,
          cs,
          Icons.access_time,
          'Created',
          _dateTimeFmt.format(activity.createdAt.toLocal()),
        ),
        _detailRow(
          theme,
          cs,
          Icons.update,
          'Updated',
          _dateTimeFmt.format(activity.updatedAt.toLocal()),
        ),
        if (activity.completedAt != null)
          _detailRow(
            theme,
            cs,
            Icons.check_circle,
            'Completed',
            _dateTimeFmt.format(activity.completedAt!.toLocal()),
          ),
        _detailRow(
            theme, cs, Icons.fingerprint, 'ID', activity.id),
        _detailRow(
            theme, cs, Icons.history, 'Version', 'v${activity.version}'),

        // Description (for narrow layout)
        if (activity.description != null &&
            activity.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _sectionTitle(theme, cs, 'Description'),
          const SizedBox(height: 8),
          Text(activity.description!, style: theme.textTheme.bodyLarge),
        ],

        // Attendees (for narrow layout)
        if (activity.isMeeting &&
            activity.attendees != null &&
            activity.attendees!.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _sectionTitle(theme, cs, 'Attendees'),
          const SizedBox(height: 8),
          ...activity.attendees!.map(
            (a) => _AttendeeRow(attendee: a),
          ),
        ],

        // Links (for narrow layout)
        if (activity.links.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _sectionTitle(theme, cs, 'Linked Entities'),
          const SizedBox(height: 8),
          ...activity.links.map((link) => _detailRow(
                theme,
                cs,
                _entityIcon(link.entityType),
                _capitalize(link.entityType),
                link.entityId,
              )),
        ],

        // Call data JSON (any extra fields)
        if (activity.data.isNotEmpty &&
            !activity.isCall) ...[
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _sectionTitle(theme, cs, 'Additional Data'),
          const SizedBox(height: 8),
          ...activity.data.entries.map((e) => _detailRow(
                theme,
                cs,
                Icons.data_object,
                _capitalize(e.key.replaceAll('_', ' ')),
                e.value?.toString() ?? '',
              )),
        ],
      ],
    );
  }

  // ── Helpers ──

  Widget _sectionTitle(ThemeData theme, ColorScheme cs, String text) {
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: cs.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _detailRow(
    ThemeData theme,
    ColorScheme cs,
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isLink ? cs.primary : null,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(Color bg, Color fg, String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ColorScheme cs) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete activity?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDeleted?.call();
  }

  IconData _typeIcon(ActivityType type) => switch (type) {
        ActivityType.task => Icons.task_alt,
        ActivityType.call => Icons.phone,
        ActivityType.meeting => Icons.event,
      };

  IconData _entityIcon(String entityType) => switch (entityType) {
        'contact' => Icons.person,
        'company' => Icons.business,
        'record' => Icons.description,
        'subscription' => Icons.subscriptions,
        'product' => Icons.inventory_2,
        _ => Icons.link,
      };

  Color _priorityColor(ActivityPriority priority) => switch (priority) {
        ActivityPriority.high => Colors.red,
        ActivityPriority.medium => Colors.orange,
        ActivityPriority.low => Colors.blue,
        ActivityPriority.none => Colors.grey,
      };

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _formatDuration(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60);
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  String _formatSeconds(num seconds) {
    final d = Duration(seconds: seconds.toInt());
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60);
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  String _formatProvider(String provider) => switch (provider) {
        'google_meet' => 'Google Meet',
        'zoom' => 'Zoom',
        'teams' => 'Microsoft Teams',
        _ => provider,
      };

  String _formatDateString(String dateStr) {
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr;
    return _dateFmt.format(parsed);
  }

  String _formatTimeString(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return timeStr;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return _timeFmt.format(dt);
  }

  void _copyToClipboard({BuildContext? context, required String text}) {
    Clipboard.setData(ClipboardData(text: text));
  }
}

/// Row showing attendee info with RSVP status.
class _AttendeeRow extends StatelessWidget {
  const _AttendeeRow({required this.attendee});

  final Map<String, dynamic> attendee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = attendee['name'] as String? ?? '';
    final email = attendee['email'] as String? ?? '';
    final rsvp = attendee['rsvp_status'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.primaryContainer,
            child: Text(
              name.isNotEmpty
                  ? name[0].toUpperCase()
                  : (email.isNotEmpty ? email[0].toUpperCase() : '?'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Text(name, style: theme.textTheme.bodyMedium),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (rsvp.isNotEmpty) _rsvpBadge(cs, rsvp),
        ],
      ),
    );
  }

  Widget _rsvpBadge(ColorScheme cs, String status) {
    final (Color bg, Color fg, IconData icon) = switch (status) {
      'accepted' => (
        Colors.green.withValues(alpha: 0.15),
        Colors.green,
        Icons.check_circle_outline,
      ),
      'declined' => (
        Colors.red.withValues(alpha: 0.15),
        Colors.red,
        Icons.cancel_outlined,
      ),
      'tentative' => (
        Colors.orange.withValues(alpha: 0.15),
        Colors.orange,
        Icons.help_outline,
      ),
      _ => (
        cs.surfaceContainerHighest,
        cs.onSurfaceVariant,
        Icons.pending_outlined,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
