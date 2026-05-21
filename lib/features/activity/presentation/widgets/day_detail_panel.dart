import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:cis_crm/features/activity/presentation/widgets/activities_calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Right-side panel showing activities for the selected day.
class DayDetailPanel extends StatelessWidget {
  const DayDetailPanel({
    super.key,
    required this.selectedDay,
    required this.activities,
    this.onActivityTap,
    this.onNewActivity,
  });

  final DateTime selectedDay;
  final List<Activity> activities;
  final ValueChanged<Activity>? onActivityTap;
  final VoidCallback? onNewActivity;

  static final _fullDateFmt = DateFormat('EEEE, MMMM d, yyyy');
  static final _timeFmt = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Sort: timed first (by due_time), then untimed.
    final sorted = List<Activity>.from(activities)
      ..sort((a, b) {
        final aTime = a.dueTime ?? '';
        final bTime = b.dueTime ?? '';
        if (aTime.isEmpty && bTime.isEmpty) return 0;
        if (aTime.isEmpty) return 1;
        if (bTime.isEmpty) return -1;
        return aTime.compareTo(bTime);
      });

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date Header ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _fullDateFmt.format(selectedDay),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Divider(color: cs.outlineVariant),
              ],
            ),
          ),
          // ── Activities List ──
          Expanded(
            child: sorted.isEmpty
                ? _EmptyDay(onNewActivity: onNewActivity)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final activity = sorted[index];
                      final showTimeHeader = index == 0 ||
                          _timeGroup(sorted[index]) !=
                              _timeGroup(sorted[index - 1]);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showTimeHeader)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 4),
                              child: Text(
                                _timeGroup(activity),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          _ActivityCard(
                            activity: activity,
                            onTap: onActivityTap != null
                                ? () => onActivityTap!(activity)
                                : null,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          // ── New Activity Button ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onNewActivity,
                icon: const Icon(Icons.add),
                label: const Text('New Activity'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeGroup(Activity activity) {
    if (activity.dueTime == null || activity.dueTime!.isEmpty) {
      return 'No specific time';
    }
    return _formatTimeString(activity.dueTime!);
  }

  String _formatTimeString(String timeStr) {
    // The backend stores due_time as "HH:mm" or "HH:mm:ss".
    final parts = timeStr.split(':');
    if (parts.length < 2) return timeStr;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return _timeFmt.format(dt);
  }
}

// ── Empty Day ──

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({this.onNewActivity});

  final VoidCallback? onNewActivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No activities scheduled',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity Card ──

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    this.onTap,
  });

  final Activity activity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = ActivityColors.forType(activity.activityType);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color dot
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4, right: 10),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (activity.dueTime != null &&
                            activity.dueTime!.isNotEmpty) ...[
                          Text(
                            _formatTime(activity.dueTime!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            ' · ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Due today',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            ' · ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                        Text(
                          _typeLabel(activity.activityType),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (activity.activityType == ActivityType.call) ...[
                          Text(
                            ' · ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _callDirection(activity.data),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (activity.priority == ActivityPriority.high) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.flag, size: 14, color: Colors.red[400]),
                          Text(
                            ' High',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.red[400],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Meeting-specific info
                    if (activity.activityType == ActivityType.meeting) ...[
                      if (activity.data['location'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 12, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                activity.data['location'] as String,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(ActivityType type) => switch (type) {
        ActivityType.meeting => 'Meeting',
        ActivityType.task => 'Task',
        ActivityType.call => 'Call',
      };

  String _callDirection(Map<String, dynamic> data) {
    final dir = data['direction'] as String?;
    if (dir == 'outbound') return 'Outbound';
    if (dir == 'inbound') return 'Inbound';
    return '';
  }

  String _formatTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return timeStr;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('h:mm a').format(dt);
  }
}
