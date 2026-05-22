import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/features/activity/data/datasources/activities_data_source.dart';
import 'package:cis_crm/features/activity/data/datasources/activity_config_service.dart';
import 'package:cis_crm/features/activity/data/models/activity_model.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:cis_crm/features/activity/presentation/widgets/activities_calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-page activity detail with double-tap inline editing.
class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({
    super.key,
    required this.activity,
    this.onStatusChanged,
    this.onDeleted,
  });

  final Activity activity;
  final VoidCallback? onStatusChanged;
  final VoidCallback? onDeleted;

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  late Activity _activity;
  String? _editingField;
  bool _saving = false;

  // Text controllers for inline editing
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Cached config
  List<ActivityStatus> _statuses = [];
  List<ActivitySubtype> _subtypes = [];

  static final _dateFmt = DateFormat('EEEE, MMMM d, yyyy');
  static final _dateTimeFmt = DateFormat('EEEE, MMMM d, yyyy · h:mm a');
  static final _timeFmt = DateFormat('h:mm a');
  static final _apiDateFmt = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _activity = widget.activity;
    _loadConfig();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = ActivityConfigService.instance;
    final typeName = _activity.activityType.name;
    final statuses = await config.getStatuses(typeName);
    final subtypes = await config.getSubtypes(typeName);
    if (mounted) {
      setState(() {
        _statuses = statuses;
        _subtypes = subtypes;
      });
    }
  }

  Future<void> _saveField(Map<String, dynamic> patch) async {
    setState(() => _saving = true);
    try {
      final ds = getIt<ActivitiesDataSource>();
      final updated = await ds.updateActivity(_activity.id, patch);
      if (mounted) {
        setState(() {
          _activity = updated;
          _editingField = null;
          _saving = false;
        });
        widget.onStatusChanged?.call();
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _startEdit(String field) {
    setState(() {
      _editingField = field;
      switch (field) {
        case 'title':
          _titleCtrl.text = _activity.title;
        case 'description':
          _descCtrl.text = _activity.description ?? '';
      }
    });
  }

  void _cancelEdit() => setState(() => _editingField = null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = ActivityColors.forType(_activity.activityType);
    final typeLabel = _capitalize(_activity.activityType.name);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(typeLabel),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (widget.onDeleted != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(cs),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        onTap: _cancelEdit,
        behavior: HitTestBehavior.translucent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 800;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 60, child: _buildMainColumn(theme, cs, color)),
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
      ),
    );
  }

  // ── Wide layout ──

  Widget _buildMainColumn(ThemeData theme, ColorScheme cs, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, cs, color),
          const SizedBox(height: 24),
          _buildDescriptionSection(theme, cs),
          if (_activity.isMeeting &&
              _activity.attendees != null &&
              _activity.attendees!.isNotEmpty) ...[
            _sectionTitle(theme, cs, 'Attendees'),
            const SizedBox(height: 8),
            ..._activity.attendees!.map((a) => _AttendeeRow(attendee: a)),
            const SizedBox(height: 24),
          ],
          if (_activity.links.isNotEmpty) ...[
            _sectionTitle(theme, cs, 'Linked To'),
            const SizedBox(height: 8),
            ..._activity.links.map((link) => ListTile(
                  dense: true,
                  leading: Icon(_entityIcon(link.entityType), size: 20),
                  title: Text(
                    '${_capitalize(link.entityType)} · ${link.entityId}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  contentPadding: EdgeInsets.zero,
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme, ColorScheme cs, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _buildAllDetails(theme, cs, color),
    );
  }

  // ── Header ──

  Widget _buildHeader(ThemeData theme, ColorScheme cs, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badges row — double-tap status/subtype/priority to edit
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _badge(color.withValues(alpha: 0.15), color,
                _capitalize(_activity.activityType.name),
                icon: _typeIcon(_activity.activityType)),
            _editableBadge(
              field: 'status',
              bg: _activity.isCompleted
                  ? Colors.green.withValues(alpha: 0.15)
                  : cs.primaryContainer,
              fg: _activity.isCompleted ? Colors.green : cs.onPrimaryContainer,
              text: _activity.statusName,
              icon: _activity.isCompleted
                  ? Icons.check_circle_outline
                  : Icons.radio_button_unchecked,
            ),
            if (_activity.subtypeName != null)
              _editableBadge(
                field: 'subtype',
                bg: cs.tertiaryContainer,
                fg: cs.onTertiaryContainer,
                text: _activity.subtypeName!,
              ),
            _editableBadge(
              field: 'priority',
              bg: _activity.priority != null &&
                      _activity.priority != ActivityPriority.none
                  ? _priorityColor(_activity.priority!).withValues(alpha: 0.15)
                  : cs.surfaceContainerHighest,
              fg: _activity.priority != null &&
                      _activity.priority != ActivityPriority.none
                  ? _priorityColor(_activity.priority!)
                  : cs.onSurfaceVariant,
              text: _activity.priority != null &&
                      _activity.priority != ActivityPriority.none
                  ? '${_capitalize(_activity.priority!.name)} Priority'
                  : 'No Priority',
              icon: Icons.flag,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Title — double-tap to edit
        _editingField == 'title'
            ? _inlineTextField(
                controller: _titleCtrl,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                onSubmit: (v) {
                  if (v.trim().isNotEmpty) {
                    _saveField({'title': v.trim()});
                  } else {
                    _cancelEdit();
                  }
                },
              )
            : GestureDetector(
                onDoubleTap: () => _startEdit('title'),
                child: Tooltip(
                  message: 'Double-click to edit',
                  child: Text(
                    _activity.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
        // Join Meeting button
        if (_activity.isMeeting &&
            _activity.meetingUrl != null &&
            _activity.meetingUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _launchUrl(_activity.meetingUrl!),
              icon: Icon(_meetingIcon(_activity.conferenceProvider)),
              label: Text(_joinLabel(_activity.conferenceProvider)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
        // Meeting time summary
        if (_activity.isMeeting && _activity.startTime != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                _meetingTimeSummary(),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Description section ──

  Widget _buildDescriptionSection(ThemeData theme, ColorScheme cs) {
    final hasDesc =
        _activity.description != null && _activity.description!.isNotEmpty;

    if (_editingField == 'description') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(theme, cs, 'Description'),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            autofocus: true,
            maxLines: 5,
            minLines: 3,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'Add a description...',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () =>
                        _saveField({'description': _descCtrl.text.trim()}),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _cancelEdit,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    return GestureDetector(
      onDoubleTap: () => _startEdit('description'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(theme, cs, 'Description'),
          const SizedBox(height: 8),
          Tooltip(
            message: 'Double-click to edit',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Text(
                hasDesc ? _activity.description! : 'No description — double-click to add',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: hasDesc ? null : cs.onSurfaceVariant,
                  fontStyle: hasDesc ? null : FontStyle.italic,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── All detail fields ──

  Widget _buildAllDetails(ThemeData theme, ColorScheme cs, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, cs, 'Details'),
        const SizedBox(height: 12),

        // Meeting-specific
        if (_activity.isMeeting) ...[
          if (_activity.startTime != null)
            _editableDateTimeRow(theme, cs, Icons.schedule, 'Start',
                _activity.startTime!, 'start_time'),
          if (_activity.endTime != null)
            _editableDateTimeRow(theme, cs, Icons.schedule, 'End',
                _activity.endTime!, 'end_time'),
          if (_activity.startTime != null && _activity.endTime != null)
            _readOnlyRow(theme, cs, Icons.timelapse, 'Duration',
                _formatDuration(_activity.endTime!.difference(_activity.startTime!))),
          if (_activity.meetingUrl != null && _activity.meetingUrl!.isNotEmpty)
            _tappableRow(theme, cs, Icons.videocam, 'Meeting Link',
                _activity.meetingUrl!, () => _launchUrl(_activity.meetingUrl!)),
          if (_activity.conferenceProvider != null)
            _readOnlyRow(theme, cs, Icons.video_call, 'Provider',
                _formatProvider(_activity.conferenceProvider!)),
          if (_activity.calendarProvider != null)
            _readOnlyRow(theme, cs, Icons.cloud_sync, 'Calendar',
                '${_capitalize(_activity.calendarProvider!)} Calendar'),
          if (_activity.calendarEventId != null)
            _readOnlyRow(theme, cs, Icons.tag, 'Event ID',
                _activity.calendarEventId!),
        ],

        // Task/Call due date/time — editable
        if (!_activity.isMeeting) ...[
          _editableDateRow(theme, cs, Icons.event, 'Due Date',
              _activity.dueDate, 'due_date'),
          _editableTimeRow(theme, cs, Icons.schedule, 'Due Time',
              _activity.dueTime, 'due_time'),
        ],

        // Call-specific — editable dropdowns
        if (_activity.isCall) ...[
          _editableDropdownRow(
            theme, cs, Icons.swap_calls, 'Direction',
            _activity.data['direction'] as String? ?? 'outbound',
            'direction',
            {'inbound': 'Inbound', 'outbound': 'Outbound'},
          ),
          _editableDropdownRow(
            theme, cs, Icons.call_end, 'Outcome',
            _activity.data['outcome'] as String? ?? '',
            'outcome',
            {
              'connected': 'Connected',
              'voicemail': 'Voicemail',
              'no_answer': 'No Answer',
              'busy': 'Busy',
            },
          ),
        ],

        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        _sectionTitle(theme, cs, 'Metadata'),
        const SizedBox(height: 12),

        if (_activity.assigneeId != null)
          _readOnlyRow(theme, cs, Icons.person, 'Assignee', _activity.assigneeId!),
        if (_activity.createdBy != null)
          _readOnlyRow(theme, cs, Icons.person_outline, 'Created By', _activity.createdBy!),
        _readOnlyRow(theme, cs, Icons.access_time, 'Created',
            _dateTimeFmt.format(_activity.createdAt.toLocal())),
        _readOnlyRow(theme, cs, Icons.update, 'Updated',
            _dateTimeFmt.format(_activity.updatedAt.toLocal())),
        if (_activity.completedAt != null)
          _readOnlyRow(theme, cs, Icons.check_circle, 'Completed',
              _dateTimeFmt.format(_activity.completedAt!.toLocal())),
        _readOnlyRow(theme, cs, Icons.fingerprint, 'ID', _activity.id),
        _readOnlyRow(theme, cs, Icons.history, 'Version', 'v${_activity.version}'),

        // Narrow layout: description
        if (_activity.description != null && _activity.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _buildDescriptionSection(Theme.of(context), Theme.of(context).colorScheme),
        ],

        // Attendees (narrow)
        if (_activity.isMeeting &&
            _activity.attendees != null &&
            _activity.attendees!.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _sectionTitle(theme, cs, 'Attendees'),
          const SizedBox(height: 8),
          ..._activity.attendees!.map((a) => _AttendeeRow(attendee: a)),
        ],

        // Links
        if (_activity.links.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _sectionTitle(theme, cs, 'Linked Entities'),
          const SizedBox(height: 8),
          ..._activity.links.map((link) => _readOnlyRow(
                theme, cs, _entityIcon(link.entityType),
                _capitalize(link.entityType), link.entityId)),
        ],
      ],
    );
  }

  // ── Editable row builders ──

  Widget _editableDateRow(ThemeData theme, ColorScheme cs, IconData icon,
      String label, String? value, String apiField) {
    final display = value != null ? _formatDateString(value) : 'Not set';
    return GestureDetector(
      onDoubleTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value != null
              ? DateTime.tryParse(value) ?? DateTime.now()
              : DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          _saveField({apiField: _apiDateFmt.format(picked)});
        }
      },
      child: Tooltip(
        message: 'Double-click to edit',
        child: _rowLayout(theme, cs, icon, label, display),
      ),
    );
  }

  Widget _editableTimeRow(ThemeData theme, ColorScheme cs, IconData icon,
      String label, String? value, String apiField) {
    final display = value != null ? _formatTimeString(value) : 'Not set';
    return GestureDetector(
      onDoubleTap: () async {
        TimeOfDay initial = TimeOfDay.now();
        if (value != null) {
          final parts = value.split(':');
          if (parts.length >= 2) {
            initial = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 0,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
        );
        if (picked != null) {
          final formatted =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
          _saveField({apiField: formatted});
        }
      },
      child: Tooltip(
        message: 'Double-click to edit',
        child: _rowLayout(theme, cs, icon, label, display),
      ),
    );
  }

  Widget _editableDateTimeRow(ThemeData theme, ColorScheme cs, IconData icon,
      String label, DateTime value, String apiField) {
    return GestureDetector(
      onDoubleTap: () async {
        final local = value.toLocal();
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: local,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (pickedDate == null || !mounted) return;
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(local),
        );
        if (pickedTime == null) return;
        final combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        ).toUtc();
        _saveField({apiField: combined.toIso8601String()});
      },
      child: Tooltip(
        message: 'Double-click to edit',
        child: _rowLayout(
            theme, cs, icon, label, _dateTimeFmt.format(value.toLocal())),
      ),
    );
  }

  Widget _editableDropdownRow(
    ThemeData theme,
    ColorScheme cs,
    IconData icon,
    String label,
    String currentValue,
    String dataKey,
    Map<String, String> options,
  ) {
    if (_editingField == dataKey) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: options.containsKey(currentValue) ? currentValue : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: options.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    final updatedData =
                        Map<String, dynamic>.from(_activity.data);
                    updatedData[dataKey] = v;
                    _saveField({'data': updatedData});
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: _cancelEdit,
            ),
          ],
        ),
      );
    }
    final display = options[currentValue] ?? _capitalize(currentValue);
    return GestureDetector(
      onDoubleTap: () => _startEdit(dataKey),
      child: Tooltip(
        message: 'Double-click to edit',
        child: _rowLayout(theme, cs, icon, label, display),
      ),
    );
  }

  Widget _editableBadge({
    required String field,
    required Color bg,
    required Color fg,
    required String text,
    IconData? icon,
  }) {
    return GestureDetector(
      onDoubleTap: () => _showFieldPicker(field),
      child: Tooltip(
        message: 'Double-click to edit',
        child: _badge(bg, fg, text, icon: icon),
      ),
    );
  }

  Future<void> _showFieldPicker(String field) async {
    switch (field) {
      case 'status':
        if (_statuses.isEmpty) return;
        final picked = await showDialog<ActivityStatus>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Change Status'),
            children: _statuses
                .map((s) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, s),
                      child: Row(
                        children: [
                          Icon(
                            s.phase == 'closed'
                                ? Icons.check_circle_outline
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: s.phase == 'closed'
                                ? Colors.green
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(s.name),
                          if (s.isDefault) ...[
                            const SizedBox(width: 8),
                            Text('(default)',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ],
                        ],
                      ),
                    ))
                .toList(),
          ),
        );
        if (picked != null) _saveField({'status_id': picked.id});

      case 'subtype':
        if (_subtypes.isEmpty) return;
        final picked = await showDialog<ActivitySubtype?>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Change Subtype'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('None'),
              ),
              ..._subtypes.map((s) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, s),
                    child: Text(s.name),
                  )),
            ],
          ),
        );
        // null from dialog close vs explicitly picking "None"
        if (picked != null) {
          _saveField({'subtype_id': picked.id});
        }

      case 'priority':
        final options = {
          'none': 'None',
          'low': 'Low',
          'medium': 'Medium',
          'high': 'High',
        };
        final picked = await showDialog<String>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Change Priority'),
            children: options.entries
                .map((e) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, e.key),
                      child: Row(
                        children: [
                          Icon(Icons.flag,
                              size: 18,
                              color: _priorityColor(
                                  ActivityPriority.values.firstWhere(
                                (p) => p.name == e.key,
                              ))),
                          const SizedBox(width: 12),
                          Text(e.value),
                        ],
                      ),
                    ))
                .toList(),
          ),
        );
        if (picked != null) _saveField({'priority': picked});
    }
  }

  // ── Row widgets ──

  Widget _readOnlyRow(ThemeData theme, ColorScheme cs, IconData icon,
      String label, String value) {
    return _rowLayout(theme, cs, icon, label, value);
  }

  Widget _tappableRow(ThemeData theme, ColorScheme cs, IconData icon,
      String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Text(value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.primary,
                    decoration: TextDecoration.underline,
                  )),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'Copy',
            onPressed: () => Clipboard.setData(ClipboardData(text: value)),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _rowLayout(ThemeData theme, ColorScheme cs, IconData icon,
      String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _inlineTextField({
    required TextEditingController controller,
    TextStyle? style,
    required ValueChanged<String> onSubmit,
  }) {
    return TextField(
      controller: controller,
      autofocus: true,
      style: style,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => onSubmit(controller.text),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelEdit,
            ),
          ],
        ),
      ),
      onSubmitted: onSubmit,
    );
  }

  // ── Shared helpers ──

  Widget _sectionTitle(ThemeData theme, ColorScheme cs, String text) {
    return Text(text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ));
  }

  Widget _badge(Color bg, Color fg, String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(ColorScheme cs) async {
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
    if (confirmed == true) widget.onDeleted?.call();
  }

  String _meetingTimeSummary() {
    final start = _activity.startTime!.toLocal();
    final buf = StringBuffer(_dateTimeFmt.format(start));
    if (_activity.endTime != null) {
      final end = _activity.endTime!.toLocal();
      if (start.year == end.year &&
          start.month == end.month &&
          start.day == end.day) {
        buf.write(' – ${_timeFmt.format(end)}');
      } else {
        buf.write(' – ${_dateTimeFmt.format(end)}');
      }
    }
    return buf.toString();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  IconData _typeIcon(ActivityType t) => switch (t) {
        ActivityType.task => Icons.task_alt,
        ActivityType.call => Icons.phone,
        ActivityType.meeting => Icons.event,
      };
  IconData _entityIcon(String t) => switch (t) {
        'contact' => Icons.person,
        'company' => Icons.business,
        'record' => Icons.description,
        'subscription' => Icons.subscriptions,
        'product' => Icons.inventory_2,
        _ => Icons.link,
      };
  IconData _meetingIcon(String? p) => switch (p) {
        'google_meet' => Icons.video_call,
        'zoom' => Icons.videocam,
        'teams' => Icons.groups,
        _ => Icons.videocam,
      };
  String _joinLabel(String? p) => switch (p) {
        'google_meet' => 'Join Google Meet',
        'zoom' => 'Join Zoom Meeting',
        'teams' => 'Join Teams Meeting',
        _ => 'Join Meeting',
      };
  Color _priorityColor(ActivityPriority p) => switch (p) {
        ActivityPriority.high => Colors.red,
        ActivityPriority.medium => Colors.orange,
        ActivityPriority.low => Colors.blue,
        ActivityPriority.none => Colors.grey,
      };
  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
  String _formatDuration(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
  String _formatProvider(String p) => switch (p) {
        'google_meet' => 'Google Meet',
        'zoom' => 'Zoom',
        'teams' => 'Microsoft Teams',
        _ => p,
      };
  String _formatDateString(String s) {
    final d = DateTime.tryParse(s);
    return d != null ? _dateFmt.format(d) : s;
  }
  String _formatTimeString(String s) {
    final p = s.split(':');
    if (p.length < 2) return s;
    final dt = DateTime(2000, 1, 1, int.tryParse(p[0]) ?? 0, int.tryParse(p[1]) ?? 0);
    return _timeFmt.format(dt);
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
                  Text(email,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
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
      'accepted' => (Colors.green.withValues(alpha: 0.15), Colors.green, Icons.check_circle_outline),
      'declined' => (Colors.red.withValues(alpha: 0.15), Colors.red, Icons.cancel_outlined),
      'tentative' => (Colors.orange.withValues(alpha: 0.15), Colors.orange, Icons.help_outline),
      _ => (cs.surfaceContainerHighest, cs.onSurfaceVariant, Icons.pending_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text('${status[0].toUpperCase()}${status.substring(1)}',
              style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
