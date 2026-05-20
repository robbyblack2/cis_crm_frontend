import 'package:cis_crm/app/injection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Reusable activities section widget for entity detail pages.
/// Shows activities linked to a contact, company, or record.
class ActivitiesSection extends StatefulWidget {
  const ActivitiesSection({
    required this.entityType,
    required this.entityId,
    super.key,
  });

  /// One of: 'contacts', 'companies', 'records'
  final String entityType;
  final String entityId;

  @override
  State<ActivitiesSection> createState() => _ActivitiesSectionState();
}

class _ActivitiesSectionState extends State<ActivitiesSection> {
  List<Map<String, dynamic>>? _activities;
  bool _loading = true;
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await getIt<Dio>().get<Map<String, dynamic>>(
        '/api/${widget.entityType}/${widget.entityId}/activities',
      );
      final list = response.data?['data'] as List<dynamic>?;
      if (mounted) {
        setState(() {
          _activities = list?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _activities = []; _loading = false; });
    }
  }

  IconData _typeIcon(String type) => switch (type) {
        'task' => Icons.task_alt,
        'call' => Icons.phone_outlined,
        'meeting' => Icons.event_outlined,
        'email' => Icons.email_outlined,
        _ => Icons.history,
      };

  Color _typeColor(String type) => switch (type) {
        'task' => Colors.blue,
        'call' => Colors.green,
        'meeting' => Colors.purple,
        'email' => Colors.orange,
        _ => Colors.grey,
      };

  Color _statusColor(String status) => switch (status) {
        'done' || 'completed' || 'sent' || 'connected' => Colors.green,
        'in_progress' || 'planned' || 'draft' => Colors.blue,
        'cancelled' || 'no_show' || 'no_answer' || 'busy' => Colors.red,
        _ => Colors.grey,
      };

  String _relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 7) {
        return '${dt.month}/${dt.day}/${dt.year}';
      }
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final count = _activities?.length ?? 0;

    var filtered = _activities ?? [];
    if (_typeFilter != null) {
      filtered = filtered
          .where((a) => a['activity_type'] == _typeFilter)
          .toList();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Activities${count > 0 ? ' ($count)' : ''}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh',
                  onPressed: () {
                    setState(() => _loading = true);
                    _load();
                  },
                ),
              ],
            ),
            // Type filter chips
            if (!_loading && count > 0) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('All', null),
                    const SizedBox(width: 6),
                    _chip('Tasks', 'task'),
                    const SizedBox(width: 6),
                    _chip('Calls', 'call'),
                    const SizedBox(width: 6),
                    _chip('Meetings', 'meeting'),
                    const SizedBox(width: 6),
                    _chip('Emails', 'email'),
                  ],
                ),
              ),
            ],
            const Divider(height: 24),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No activities yet',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...filtered.map((activity) {
                final type =
                    activity['activity_type'] as String? ?? 'task';
                final title = activity['title'] as String? ?? 'Activity';
                final status = activity['status'] as String? ?? '';
                final dueDate = activity['due_date'] as String?;
                final createdAt = activity['created_at'] as String?;
                final description =
                    activity['description'] as String? ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type icon
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            _typeColor(type).withValues(alpha: 0.12),
                        child: Icon(
                          _typeIcon(type),
                          size: 16,
                          color: _typeColor(type),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (description.isNotEmpty)
                              Text(
                                description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: [
                                // Status chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status)
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.replaceAll('_', ' '),
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                      color: _statusColor(status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                // Due date or created at
                                if (dueDate != null)
                                  Text(
                                    'Due: $dueDate',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                Text(
                                  _relativeTime(createdAt),
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String? value) {
    final isSelected = _typeFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _typeFilter = value),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
