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
      child: const _TasksView(),
    );
  }
}

class _TasksView extends StatefulWidget {
  const _TasksView();

  @override
  State<_TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<_TasksView> {
  Set<String> _phaseFilter = {};
  Set<String> _typeFilter = {};
  Set<String> _priorityFilter = {};
  String _search = '';
  bool _calendarView = true;
  bool _sidebarOpen = false;

  @override
  Widget build(BuildContext context) {
    if (_calendarView) {
      return _buildCalendarView(context);
    }

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
          TasksLoaded(:final tasks) => _buildListView(context, tasks),
        };
      },
    );
  }

  // ── Calendar View ──

  Widget _buildCalendarView(BuildContext context) {
    return BlocBuilder<CalendarActivitiesBloc, CalendarActivitiesState>(
      builder: (context, calState) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Activities'),
            actions: [_viewToggle()],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              if (width >= 1200) {
                return Row(
                  children: [
                    Expanded(
                      flex: 65,
                      child: ActivitiesCalendarView(
                        onActivityTap: _onActivityTap,
                      ),
                    ),
                    Expanded(
                      flex: 35,
                      child: DayDetailPanel(
                        selectedDay: calState.selectedDay,
                        activities: calState.selectedDayActivities,
                        onActivityTap: _onActivityTap,
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
                        onActivityTap: _onActivityTap,
                      ),
                    ),
                    Expanded(
                      flex: 40,
                      child: DayDetailPanel(
                        selectedDay: calState.selectedDay,
                        activities: calState.selectedDayActivities,
                        onActivityTap: _onActivityTap,
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
                onActivityTap: _onActivityTap,
              );
            },
          ),
        );
      },
    );
  }

  void _refreshAll() {
    context.read<TasksBloc>().add(const TasksLoadRequested());
    context.read<CalendarActivitiesBloc>().add(
          const CalendarRefreshRequested(),
        );
  }

  void _onActivityTap(Activity activity) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailPage(
          activity: activity,
          onStatusChanged: () {
            Navigator.pop(context);
            _refreshAll();
          },
          onDeleted: () {
            Navigator.pop(context);
            context.read<TasksBloc>().add(TaskDeleted(activity.id));
            context.read<CalendarActivitiesBloc>().add(
                  const CalendarRefreshRequested(),
                );
          },
        ),
      ),
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
            onActivityTap: _onActivityTap,
            onNewActivity: () {
              Navigator.pop(context);
              _showCreateSheet(context);
            },
          ),
        ),
      ),
    );
  }

  // ── List View ──

  Widget _buildListView(BuildContext context, List<Activity> tasks) {
    var filtered = _search.isEmpty
        ? tasks
        : tasks.where((t) {
            final q = _search.toLowerCase();
            return t.title.toLowerCase().contains(q) ||
                (t.description?.toLowerCase().contains(q) ?? false);
          }).toList();

    if (_phaseFilter.isNotEmpty) {
      filtered =
          filtered.where((t) => _phaseFilter.contains(t.statusPhase)).toList();
    }
    if (_typeFilter.isNotEmpty) {
      filtered = filtered
          .where((t) => _typeFilter.contains(t.activityType.name))
          .toList();
    }
    if (_priorityFilter.isNotEmpty) {
      filtered = filtered
          .where(
              (t) => t.priority != null && _priorityFilter.contains(t.priority!.name))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        actions: [
          IconButton(
            icon: Icon(_sidebarOpen ? Icons.filter_list_off : Icons.filter_list),
            tooltip: 'Filters',
            onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
          ),
          _viewToggle(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search activities...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
              icon: Icons.task_alt,
              title: AppLocalizations.of(context)!.tasksEmpty,
              message: AppLocalizations.of(context)!.tasksEmptyAction,
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final activity = filtered[index];
                return _ActivityListTile(
                  activity: activity,
                  onTap: () => _onActivityTap(activity),
                  onToggleComplete: () => _toggleComplete(context, activity),
                );
              },
            ),
          ),
          if (_sidebarOpen)
            FilterSidebar(
              totalCount: tasks.length,
              resultCount: filtered.length,
              onClearAll: () => setState(() {
                _phaseFilter = {};
                _typeFilter = {};
                _priorityFilter = {};
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
                  title: 'Type',
                  options: const [
                    FilterOption(value: 'task', label: 'Task'),
                    FilterOption(value: 'call', label: 'Call'),
                    FilterOption(value: 'meeting', label: 'Meeting'),
                  ],
                  selected: _typeFilter,
                  onChanged: (v) => setState(() => _typeFilter = v),
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
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tasks_fab',
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Activity'),
      ),
    );
  }

  Future<void> _toggleComplete(BuildContext context, Activity activity) async {
    final config = ActivityConfigService.instance;
    final typeName = activity.activityType.name;

    if (activity.isCompleted) {
      // Reopen: set to the default open status.
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
        context.read<CalendarActivitiesBloc>().add(
              const CalendarRefreshRequested(),
            );
      }
    } else {
      // Complete: set to the first closed status.
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
        context.read<CalendarActivitiesBloc>().add(
              const CalendarRefreshRequested(),
            );
      }
    }
  }

  // ── Shared Widgets ──

  Widget _viewToggle() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: true,
          icon: Icon(Icons.calendar_month, size: 18),
          label: Text('Calendar'),
        ),
        ButtonSegment(
          value: false,
          icon: Icon(Icons.view_list, size: 18),
          label: Text('List'),
        ),
      ],
      selected: {_calendarView},
      onSelectionChanged: (v) => setState(() => _calendarView = v.first),
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
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
}

/// Simple activity list tile for the list view.
class _ActivityListTile extends StatelessWidget {
  const _ActivityListTile({
    required this.activity,
    this.onTap,
    this.onToggleComplete,
  });

  final Activity activity;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;

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
          if (activity.dueDate != null) ...[
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

/// Full activity creation form with type, title, status, subtype, due date.
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
  var _type = ActivityType.task;
  ActivityStatus? _status;
  ActivitySubtype? _subtype;
  ActivityPriority? _priority;
  DateTime? _dueDate;
  List<ActivityStatus> _statuses = [];
  List<ActivitySubtype> _subtypes = [];
  bool _loadingConfig = true;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.prefilledDate;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                              _status = _statuses.firstWhere((s) => s.id == id);
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ActivityPriority>(
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                          _dueDate != null
                              ? DateFormat.yMMMd().format(_dueDate!)
                              : 'Set due date',
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
                    ),
                  ],
                ),
              ],
            ),
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
      dueDate: _dueDate != null
          ? DateFormat('yyyy-MM-dd').format(_dueDate!)
          : null,
    );
    widget.onCreated(activity);
  }
}

