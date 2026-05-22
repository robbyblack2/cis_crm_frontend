import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/filter_sidebar.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/activity/data/datasources/activity_config_service.dart';
import 'package:cis_crm/features/activity/data/models/activity_model.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:cis_crm/features/activity/presentation/bloc/calendar_activities_bloc.dart';
import 'package:cis_crm/features/activity/presentation/bloc/tasks_bloc.dart';
import 'package:cis_crm/features/activity/presentation/pages/activity_detail_page.dart';
import 'package:cis_crm/features/activity/presentation/widgets/activities_calendar_view.dart';
import 'package:cis_crm/features/activity/presentation/widgets/day_detail_panel.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<TasksBloc>()..add(const TasksLoadRequested()),
        ),
        BlocProvider(
          create: (_) =>
              getIt<CalendarActivitiesBloc>()
                ..add(CalendarMonthRequested(
                  month: DateTime(DateTime.now().year, DateTime.now().month),
                )),
        ),
      ],
      child: const _ActivitiesTabView(),
    );
  }
}

// ── Tab Shell ──────────────────────────────────────────────────────────

class _ActivitiesTabView extends StatelessWidget {
  const _ActivitiesTabView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 1,
            child: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
                Tab(icon: Icon(Icons.task_alt), text: 'Tasks'),
                Tab(icon: Icon(Icons.event), text: 'Meetings'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _CalendarTab(),
                _TypedActivityTab(activityType: ActivityType.task),
                _TypedActivityTab(activityType: ActivityType.meeting),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Calendar Tab ───────────────────────────────────────────────────────

class _CalendarTab extends StatelessWidget {
  const _CalendarTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarActivitiesBloc, CalendarActivitiesState>(
      builder: (context, calState) {
        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              if (width >= 1200) {
                return Row(
                  children: [
                    Expanded(
                      flex: 65,
                      child: ActivitiesCalendarView(
                        onActivityTap: (a) => _onActivityTap(context, a),
                      ),
                    ),
                    Expanded(
                      flex: 35,
                      child: DayDetailPanel(
                        selectedDay: calState.selectedDay,
                        activities: calState.selectedDayActivities,
                        onActivityTap: (a) => _onActivityTap(context, a),
                        onNewActivity: () => _showCreateSheet(context),
                      ),
                    ),
                  ],
                );
              }

              if (width >= 800) {
                return Column(
                  children: [
                    Expanded(
                      flex: 60,
                      child: ActivitiesCalendarView(
                        onActivityTap: (a) => _onActivityTap(context, a),
                      ),
                    ),
                    Expanded(
                      flex: 40,
                      child: DayDetailPanel(
                        selectedDay: calState.selectedDay,
                        activities: calState.selectedDayActivities,
                        onActivityTap: (a) => _onActivityTap(context, a),
                        onNewActivity: () => _showCreateSheet(context),
                      ),
                    ),
                  ],
                );
              }

              return ActivitiesCalendarView(
                onDaySelected: (day) {
                  _showDayDetailPage(context, calState, day);
                },
                onActivityTap: (a) => _onActivityTap(context, a),
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'calendar_fab',
            onPressed: () => _showCreateSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('New Activity'),
          ),
        );
      },
    );
  }

  void _showDayDetailPage(
    BuildContext context,
    CalendarActivitiesState state,
    DateTime day,
  ) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(DateFormat.yMMMMd().format(day))),
          body: DayDetailPanel(
            selectedDay: day,
            activities: state.activitiesForDay(day),
            onActivityTap: (a) => _onActivityTap(context, a),
            onNewActivity: () {
              Navigator.pop(context);
              _showCreateSheet(context);
            },
          ),
        ),
      ),
    );
  }
}

// ── Typed Activity Tab (Tasks or Meetings) ────────────────────────────

class _TypedActivityTab extends StatefulWidget {
  const _TypedActivityTab({required this.activityType});

  final ActivityType activityType;

  @override
  State<_TypedActivityTab> createState() => _TypedActivityTabState();
}

class _TypedActivityTabState extends State<_TypedActivityTab> {
  Set<String> _phaseFilter = {};
  Set<String> _priorityFilter = {};
  Set<String> _subtypeFilter = {};
  String _search = '';
  bool _sidebarOpen = false;

  bool get _isMeetings => widget.activityType == ActivityType.meeting;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksBloc, TasksState>(
      builder: (context, state) {
        return switch (state) {
          TasksInitial() ||
          TasksLoading() =>
            PageLoading(label: AppLocalizations.of(context)!.tasksLoading),
          TasksError(:final message) => PageError(
              title: AppLocalizations.of(context)!.failedToLoadTasks,
              message: message,
              onRetry: () =>
                  context.read<TasksBloc>().add(const TasksLoadRequested()),
            ),
          TasksLoaded(:final tasks) => _buildList(context, tasks),
        };
      },
    );
  }

  Widget _buildList(BuildContext context, List<Activity> allActivities) {
    // Filter to this tab's type
    var filtered = allActivities
        .where((a) => a.activityType == widget.activityType)
        .toList();

    final totalForType = filtered.length;

    // Collect available subtypes for filter options
    final availableSubtypes = filtered
        .map((a) => a.subtypeName)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    // Apply search
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered.where((a) {
        return a.title.toLowerCase().contains(q) ||
            (a.description?.toLowerCase().contains(q) ?? false) ||
            a.statusName.toLowerCase().contains(q) ||
            (a.subtypeName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Apply filters
    if (_phaseFilter.isNotEmpty) {
      filtered = filtered
          .where((a) => _phaseFilter.contains(a.statusPhase))
          .toList();
    }
    if (_priorityFilter.isNotEmpty) {
      filtered = filtered
          .where((a) =>
              a.priority != null &&
              _priorityFilter.contains(a.priority!.name))
          .toList();
    }
    if (_subtypeFilter.isNotEmpty) {
      filtered = filtered
          .where((a) =>
              a.subtypeName != null &&
              _subtypeFilter.contains(a.subtypeName))
          .toList();
    }

    final activeCount = (_phaseFilter.isNotEmpty ? 1 : 0) +
        (_priorityFilter.isNotEmpty ? 1 : 0) +
        (_subtypeFilter.isNotEmpty ? 1 : 0);

    // Build active filter chips
    final activeFilters = <ActiveFilter>[
      for (final p in _phaseFilter)
        ActiveFilter(
          label: 'Phase: $p',
          onRemove: () => setState(() {
            _phaseFilter = Set.from(_phaseFilter)..remove(p);
          }),
        ),
      for (final p in _priorityFilter)
        ActiveFilter(
          label: 'Priority: $p',
          onRemove: () => setState(() {
            _priorityFilter = Set.from(_priorityFilter)..remove(p);
          }),
        ),
      for (final s in _subtypeFilter)
        ActiveFilter(
          label: '${_isMeetings ? "Type" : "Subtype"}: $s',
          onRemove: () => setState(() {
            _subtypeFilter = Set.from(_subtypeFilter)..remove(s);
          }),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isMeetings ? 'Meetings' : 'Tasks'),
        actions: [
          FilterToggleButton(
            activeCount: activeCount,
            isOpen: _sidebarOpen,
            onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: _isMeetings
                    ? 'Search meetings...'
                    : 'Search tasks...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                ActiveFilterChips(filters: activeFilters),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyState(
                          icon: _isMeetings
                              ? Icons.event_busy
                              : Icons.task_alt,
                          title: _isMeetings
                              ? 'No meetings'
                              : AppLocalizations.of(context)!.tasksEmpty,
                          message: _isMeetings
                              ? 'No meetings match your filters.'
                              : AppLocalizations.of(context)!
                                    .tasksEmptyAction,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 2),
                          itemBuilder: (context, index) {
                            final activity = filtered[index];
                            return _ActivityListTile(
                              activity: activity,
                              onTap: () =>
                                  _onActivityTap(context, activity),
                              onToggleComplete: () =>
                                  _toggleComplete(context, activity),
                              showTimeInfo: _isMeetings,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (_sidebarOpen)
            FilterSidebar(
              totalCount: totalForType,
              resultCount: filtered.length,
              onClearAll: () => setState(() {
                _phaseFilter = {};
                _priorityFilter = {};
                _subtypeFilter = {};
              }),
              sections: [
                FilterSection.checkboxGroup(
                  title: 'Phase',
                  options: const [
                    FilterOption(value: 'open', label: 'Open'),
                    FilterOption(value: 'closed', label: 'Closed'),
                  ],
                  selected: _phaseFilter,
                  onChanged: (v) => setState(() => _phaseFilter = v),
                ),
                FilterSection.checkboxGroup(
                  title: 'Priority',
                  options: const [
                    FilterOption(value: 'low', label: 'Low'),
                    FilterOption(value: 'medium', label: 'Medium'),
                    FilterOption(value: 'high', label: 'High'),
                  ],
                  selected: _priorityFilter,
                  onChanged: (v) => setState(() => _priorityFilter = v),
                ),
                if (availableSubtypes.isNotEmpty)
                  FilterSection.checkboxGroup(
                    title: _isMeetings ? 'Meeting Type' : 'Subtype',
                    options: availableSubtypes
                        .map((s) => FilterOption(value: s, label: s))
                        .toList(),
                    selected: _subtypeFilter,
                    onChanged: (v) => setState(() => _subtypeFilter = v),
                  ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: _isMeetings ? 'meetings_fab' : 'tasks_fab',
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add),
        label: Text(_isMeetings ? 'New Meeting' : 'New Task'),
      ),
    );
  }

  Future<void> _toggleComplete(
    BuildContext context,
    Activity activity,
  ) async {
    final config = ActivityConfigService.instance;
    final typeName = activity.activityType.name;

    if (activity.isCompleted) {
      final defaultStatus = await config.getDefaultStatus(typeName);
      if (defaultStatus == null) return;
      final updated = ActivityModel(
        id: activity.id,
        activityType: activity.activityType,
        title: activity.title,
        statusId: defaultStatus.id,
        statusName: defaultStatus.name,
        statusPhase: defaultStatus.phase,
        createdAt: activity.createdAt,
        updatedAt: activity.updatedAt,
        description: activity.description,
        priority: activity.priority,
        assigneeId: activity.assigneeId,
        subtypeId: activity.subtypeId,
        subtypeName: activity.subtypeName,
        dueDate: activity.dueDate,
        dueTime: activity.dueTime,
        data: activity.data,
        links: activity.links,
      );
      if (context.mounted) {
        context.read<TasksBloc>().add(TaskUpdateRequested(task: updated));
        context
            .read<CalendarActivitiesBloc>()
            .add(const CalendarRefreshRequested());
      }
    } else {
      final closedStatus = await config.getClosedStatus(typeName);
      if (closedStatus == null) return;
      final updated = ActivityModel(
        id: activity.id,
        activityType: activity.activityType,
        title: activity.title,
        statusId: closedStatus.id,
        statusName: closedStatus.name,
        statusPhase: closedStatus.phase,
        createdAt: activity.createdAt,
        updatedAt: activity.updatedAt,
        description: activity.description,
        priority: activity.priority,
        assigneeId: activity.assigneeId,
        subtypeId: activity.subtypeId,
        subtypeName: activity.subtypeName,
        dueDate: activity.dueDate,
        dueTime: activity.dueTime,
        data: activity.data,
        links: activity.links,
      );
      if (context.mounted) {
        context.read<TasksBloc>().add(TaskUpdateRequested(task: updated));
        context
            .read<CalendarActivitiesBloc>()
            .add(const CalendarRefreshRequested());
      }
    }
  }
}

// ── Shared Helpers ─────────────────────────────────────────────────────

void _refreshAll(BuildContext context) {
  context.read<TasksBloc>().add(const TasksLoadRequested());
  context
      .read<CalendarActivitiesBloc>()
      .add(const CalendarRefreshRequested());
}

void _onActivityTap(BuildContext context, Activity activity) {
  Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => ActivityDetailPage(
        activity: activity,
        onStatusChanged: () {
          Navigator.pop(context);
          _refreshAll(context);
        },
        onDeleted: () {
          Navigator.pop(context);
          context.read<TasksBloc>().add(TaskDeleted(activity.id));
          context
              .read<CalendarActivitiesBloc>()
              .add(const CalendarRefreshRequested());
        },
      ),
    ),
  );
}

void _showCreateSheet(BuildContext context, {DateTime? prefilledDate}) {
  Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => _CreateActivityForm(
        prefilledDate: prefilledDate,
        onCreated: (activity) {
          Navigator.pop(context);
          context.read<TasksBloc>().add(
                TaskCreateRequested(task: activity),
              );
          context.read<CalendarActivitiesBloc>().add(
                const CalendarRefreshRequested(),
              );
        },
      ),
    ),
  );
}

// ── Activity List Tile ─────────────────────────────────────────────────

class _ActivityListTile extends StatelessWidget {
  const _ActivityListTile({
    required this.activity,
    this.onTap,
    this.onToggleComplete,
    this.showTimeInfo = false,
  });

  final Activity activity;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final bool showTimeInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isClosed = activity.isCompleted;

    return ListTile(
      leading: IconButton(
        icon: Icon(
          isClosed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isClosed ? Colors.green : cs.onSurfaceVariant,
        ),
        onPressed: onToggleComplete,
        tooltip: isClosed ? 'Reopen' : 'Complete',
      ),
      title: Text(
        activity.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          decoration: isClosed ? TextDecoration.lineThrough : null,
          color: isClosed ? cs.onSurfaceVariant : null,
        ),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              activity.statusName,
              style:
                  theme.textTheme.labelSmall?.copyWith(fontSize: 10),
            ),
          ),
          if (activity.subtypeName != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                activity.subtypeName!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onTertiaryContainer,
                  fontSize: 10,
                ),
              ),
            ),
          ],
          // Show time info for meetings
          if (showTimeInfo && activity.startTime != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.schedule, size: 12, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              DateFormat.jm().format(activity.startTime!),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (activity.endTime != null) ...[
              Text(
                ' – ${DateFormat.jm().format(activity.endTime!)}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ],
          // Show due date for tasks
          if (!showTimeInfo && activity.dueDate != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.calendar_today, size: 12, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              activity.dueDate!,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          if (activity.priority == ActivityPriority.high) ...[
            const SizedBox(width: 8),
            Icon(Icons.flag, size: 12, color: Colors.red[400]),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: onTap,
    );
  }
}

// ── Create Activity Form ───────────────────────────────────────────────

class _CreateActivityForm extends StatefulWidget {
  const _CreateActivityForm({this.prefilledDate, required this.onCreated});

  final DateTime? prefilledDate;
  final ValueChanged<ActivityModel> onCreated;

  @override
  State<_CreateActivityForm> createState() => _CreateActivityFormState();
}

class _CreateActivityFormState extends State<_CreateActivityForm> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _attendeeCtrl = TextEditingController();
  var _type = ActivityType.task;
  ActivityStatus? _status;
  ActivitySubtype? _subtype;
  ActivityPriority? _priority;
  DateTime? _dueDate;
  // Meeting-specific
  DateTime? _startTime;
  DateTime? _endTime;
  final List<Map<String, dynamic>> _attendees = [];
  List<ActivityStatus> _statuses = [];
  List<ActivitySubtype> _subtypes = [];
  bool _loadingConfig = true;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.prefilledDate ?? DateTime.now();
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    _startTime = nextHour;
    _endTime = nextHour.add(const Duration(minutes: 30));
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = ActivityConfigService.instance;
    final statuses = await config.getStatuses(_type.name);
    final subtypes = await config.getSubtypes(_type.name);
    if (mounted) {
      setState(() {
        _statuses = statuses;
        _subtypes = subtypes;
        _status = statuses.cast<ActivityStatus?>().firstWhere(
              (s) => s!.isDefault,
              orElse: () => statuses.isNotEmpty ? statuses.first : null,
            );
        _loadingConfig = false;
      });
    }
  }

  Future<void> _onTypeChanged(ActivityType type) async {
    setState(() {
      _type = type;
      _loadingConfig = true;
      _status = null;
      _subtype = null;
    });
    await _loadConfig();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _attendeeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Activity'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          FilledButton(
            onPressed: _submit,
            child: const Text('Create'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loadingConfig
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Type selector
                SegmentedButton<ActivityType>(
                  segments: const [
                    ButtonSegment(
                      value: ActivityType.task,
                      label: Text('Task'),
                      icon: Icon(Icons.task_alt, size: 16),
                    ),
                    ButtonSegment(
                      value: ActivityType.call,
                      label: Text('Call'),
                      icon: Icon(Icons.phone, size: 16),
                    ),
                    ButtonSegment(
                      value: ActivityType.meeting,
                      label: Text('Meeting'),
                      icon: Icon(Icons.event, size: 16),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (v) => _onTypeChanged(v.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  minLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_statuses.isNotEmpty)
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _status?.id,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: _statuses
                              .map((s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name),
                                  ))
                              .toList(),
                          onChanged: (id) {
                            setState(() {
                              _status =
                                  _statuses.firstWhere((s) => s.id == id);
                            });
                          },
                        ),
                      ),
                    if (_statuses.isNotEmpty && _subtypes.isNotEmpty)
                      const SizedBox(width: 12),
                    if (_subtypes.isNotEmpty)
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _subtype?.id,
                          decoration: const InputDecoration(
                            labelText: 'Subtype',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              child: Text('None'),
                            ),
                            ..._subtypes.map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                )),
                          ],
                          onChanged: (id) {
                            setState(() {
                              _subtype = id != null
                                  ? _subtypes
                                      .cast<ActivitySubtype?>()
                                      .firstWhere((s) => s!.id == id,
                                          orElse: () => null)
                                  : null;
                            });
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Priority
                DropdownButtonFormField<ActivityPriority>(
                  value: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(child: Text('None')),
                    DropdownMenuItem(
                      value: ActivityPriority.low,
                      child: Text('Low'),
                    ),
                    DropdownMenuItem(
                      value: ActivityPriority.medium,
                      child: Text('Medium'),
                    ),
                    DropdownMenuItem(
                      value: ActivityPriority.high,
                      child: Text('High'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _priority = v),
                ),
                const SizedBox(height: 12),
                // Meeting: start/end time pickers + attendees
                if (_type == ActivityType.meeting) ...[
                  _dateTimePickerRow(
                    label: 'Start Time *',
                    value: _startTime!,
                    onChanged: (dt) => setState(() {
                      _startTime = dt;
                      // Always set end = start + 30 min
                      _endTime = dt.add(const Duration(minutes: 30));
                    }),
                  ),
                  const SizedBox(height: 12),
                  _dateTimePickerRow(
                    label: 'End Time *',
                    value: _endTime!,
                    onChanged: (dt) => setState(() => _endTime = dt),
                  ),
                  const SizedBox(height: 16),
                  // Attendees
                  Text('Attendees',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _attendeeCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Enter email address',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: Icon(Icons.person_add, size: 20),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onSubmitted: (_) => _addAttendee(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addAttendee,
                        icon: const Icon(Icons.add),
                        tooltip: 'Add attendee',
                      ),
                    ],
                  ),
                  if (_attendees.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._attendees.asMap().entries.map((entry) {
                      final i = entry.key;
                      final a = entry.value;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          child: Text(
                            (a['email'] as String)[0].toUpperCase(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        title: Text(
                          a['email'] as String,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () =>
                              setState(() => _attendees.removeAt(i)),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'A Google Meet link will be created automatically',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
                // Task/Call: due date
                if (_type != ActivityType.meeting) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      _dueDate != null
                          ? 'Due: ${DateFormat.yMMMd().format(_dueDate!)}'
                          : 'Set due date',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _dueDate = picked);
                      }
                    },
                  ),
                ],
              ],
            ),
    );
  }

  void _addAttendee() {
    final email = _attendeeCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) return;
    if (_attendees.any((a) => a['email'] == email)) return;
    setState(() {
      _attendees.add({'email': email, 'rsvp_status': 'needs_action'});
      _attendeeCtrl.clear();
    });
  }

  Widget _dateTimePickerRow({
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
  }) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.schedule),
      label: Text(
        '$label: ${DateFormat('EEE, MMM d · h:mm a').format(value)}',
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (pickedDate == null || !mounted) return;
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        if (pickedTime == null) return;
        onChanged(DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        ));
      },
    );
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    if (_status == null) return;

    final now = DateTime.now();
    final activity = ActivityModel(
      id: '',
      activityType: _type,
      title: title,
      statusId: _status!.id,
      statusName: _status!.name,
      statusPhase: _status!.phase,
      createdAt: now,
      updatedAt: now,
      description:
          _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      priority: _priority,
      subtypeId: _subtype?.id,
      subtypeName: _subtype?.name,
      dueDate: _type != ActivityType.meeting && _dueDate != null
          ? DateFormat('yyyy-MM-dd').format(_dueDate!)
          : null,
      startTime: _type == ActivityType.meeting ? _startTime : null,
      endTime: _type == ActivityType.meeting ? _endTime : null,
      attendees:
          _type == ActivityType.meeting && _attendees.isNotEmpty
              ? _attendees
              : null,
    );
    widget.onCreated(activity);
  }
}
