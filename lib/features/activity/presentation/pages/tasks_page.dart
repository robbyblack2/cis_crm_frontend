import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/activity/domain/entities/crm_task.dart';
import 'package:cis_crm/features/activity/domain/entities/task_priority.dart';
import 'package:cis_crm/features/activity/domain/entities/task_status.dart';
import 'package:cis_crm/features/activity/domain/repositories/calendar_activity_repository.dart';
import 'package:cis_crm/features/activity/presentation/bloc/calendar_activities_bloc.dart';
import 'package:cis_crm/features/activity/presentation/bloc/tasks_bloc.dart';
import 'package:cis_crm/features/activity/presentation/pages/task_detail_page.dart';
import 'package:cis_crm/features/activity/presentation/widgets/activities_calendar_view.dart';
import 'package:cis_crm/features/activity/presentation/widgets/day_detail_panel.dart';
import 'package:cis_crm/features/activity/presentation/widgets/task_tile.dart';
import 'package:cis_crm/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          create: (_) => CalendarActivitiesBloc(
            repository: getIt<CalendarActivityRepository>(),
          )..add(CalendarMonthRequested(
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
  TaskStatus? _filter;
  String _search = '';
  // Calendar is the default view per issue #193.
  bool _calendarView = true;

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
            actions: [
              _viewToggle(),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              if (width >= 1200) {
                // Desktop: calendar 65% + day detail 35%
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
                        onNewActivity: () => _showCreateTaskSheet(context),
                      ),
                    ),
                  ],
                );
              }

              if (width >= 800) {
                // Tablet: calendar on top, day detail below
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
                        onNewActivity: () => _showCreateTaskSheet(context),
                      ),
                    ),
                  ],
                );
              }

              // Mobile: just calendar, tap day to navigate
              return ActivitiesCalendarView(
                onDaySelected: (day) {
                  _showDayDetailSheet(context, calState, day);
                },
                onActivityTap: _onActivityTap,
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'tasks_fab',
            tooltip: 'New Activity',
            onPressed: () => _showCreateTaskSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('New Activity'),
          ),
        );
      },
    );
  }

  void _onActivityTap(activity) {
    // For now, activities don't have a dedicated detail page.
    // TODO: Navigate to activity detail when available.
  }

  void _showDayDetailSheet(
    BuildContext context,
    CalendarActivitiesState state,
    DateTime day,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: DayDetailPanel(
          selectedDay: day,
          activities: state.activitiesForDay(day),
          onActivityTap: _onActivityTap,
          onNewActivity: () {
            Navigator.pop(context);
            _showCreateTaskSheet(context);
          },
        ),
      ),
    );
  }

  // ── List View ──

  Widget _buildListView(BuildContext context, List<CrmTask> tasks) {
    var filtered = _search.isEmpty
        ? tasks
        : tasks.where((t) {
            final q = _search.toLowerCase();
            return t.title.toLowerCase().contains(q) ||
                (t.description?.toLowerCase().contains(q) ?? false);
          }).toList();

    if (_filter != null) {
      filtered = filtered.where((t) => t.status == _filter).toList();
    }

    final todoCount = tasks.where((t) => t.status == TaskStatus.todo).length;
    final ipCount =
        tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final doneCount = tasks.where((t) => t.status == TaskStatus.done).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        actions: [
          _viewToggle(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
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
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _filterChip(
                      context,
                      label: 'All (${tasks.length})',
                      value: null,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      context,
                      label: 'To Do ($todoCount)',
                      value: TaskStatus.todo,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      context,
                      label: 'In Progress ($ipCount)',
                      value: TaskStatus.inProgress,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      context,
                      label: 'Done ($doneCount)',
                      value: TaskStatus.done,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: filtered.isEmpty
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
                final task = filtered[index];
                return TaskTile(
                  task: task,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: context.read<TasksBloc>(),
                        child: TaskDetailPage(task: task),
                      ),
                    ),
                  ),
                  onStatusToggled: (updated) =>
                      context.read<TasksBloc>().add(TaskUpdated(updated)),
                  onDeleted: (id) =>
                      context.read<TasksBloc>().add(TaskDeleted(id)),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tasks_fab',
        tooltip: AppLocalizations.of(context)!.addTask,
        onPressed: () => _showCreateTaskSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
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
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _filterChip(
    BuildContext context, {
    required String label,
    required TaskStatus? value,
  }) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  void _showCreateTaskSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var priority = TaskPriority.medium;
    var status = TaskStatus.todo;
    DateTime? dueDate;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'New Task',
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<TaskPriority>(
                        value: priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: TaskPriority.values
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p.name[0].toUpperCase() +
                                      p.name.substring(1),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setSheetState(() => priority = v);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<TaskStatus>(
                        value: status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: TaskStatus.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s == TaskStatus.inProgress
                                      ? 'In Progress'
                                      : s.name[0].toUpperCase() +
                                          s.name.substring(1),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setSheetState(() => status = v);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    dueDate != null
                        ? 'Due: ${dueDate!.year}-'
                            '${dueDate!.month.toString().padLeft(2, '0')}-'
                            '${dueDate!.day.toString().padLeft(2, '0')}'
                        : 'Set due date',
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setSheetState(() => dueDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    final now = DateTime.now();
                    final authState = getIt<AuthBloc>().state;
                    final userId = authState is AuthAuthenticated
                        ? authState.user.id
                        : null;
                    final task = CrmTask(
                      id: '',
                      title: title,
                      description: descCtrl.text.trim().isNotEmpty
                          ? descCtrl.text.trim()
                          : null,
                      status: status,
                      priority: priority,
                      createdBy: userId,
                      dueDate: dueDate,
                      createdAt: now,
                      updatedAt: now,
                    );
                    context
                        .read<TasksBloc>()
                        .add(TaskCreateRequested(task: task));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Create Task'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
