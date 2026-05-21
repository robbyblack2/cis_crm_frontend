import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:cis_crm/features/activity/domain/repositories/calendar_activity_repository.dart';
import 'package:cis_crm/features/activity/presentation/bloc/calendar_activities_bloc.dart';
import 'package:cis_crm/features/activity/presentation/bloc/tasks_bloc.dart';
import 'package:cis_crm/features/activity/presentation/widgets/activities_calendar_view.dart';
import 'package:cis_crm/features/activity/presentation/widgets/day_detail_panel.dart';
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
  String? _phaseFilter; // null = all, "open", "closed"
  String _search = '';
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
                  _showDayDetailSheet(context, calState, day);
                },
                onActivityTap: _onActivityTap,
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'tasks_fab',
            onPressed: () => _showCreateSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('New Activity'),
          ),
        );
      },
    );
  }

  void _onActivityTap(activity) {}

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
            _showCreateSheet(context);
          },
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

    if (_phaseFilter != null) {
      filtered =
          filtered.where((t) => t.statusPhase == _phaseFilter).toList();
    }

    final openCount = tasks.where((t) => t.statusPhase == 'open').length;
    final closedCount = tasks.where((t) => t.statusPhase == 'closed').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        actions: [_viewToggle()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _phaseChip(
                      context,
                      label: 'All (${tasks.length})',
                      value: null,
                    ),
                    const SizedBox(width: 8),
                    _phaseChip(
                      context,
                      label: 'Open ($openCount)',
                      value: 'open',
                    ),
                    const SizedBox(width: 8),
                    _phaseChip(
                      context,
                      label: 'Closed ($closedCount)',
                      value: 'closed',
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
                final activity = filtered[index];
                return _ActivityListTile(
                  activity: activity,
                  onTap: () => _onActivityTap(activity),
                  onToggleComplete: () {
                    // Toggle between open/closed not implemented yet —
                    // requires fetching available statuses.
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tasks_fab',
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Activity'),
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
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
    );
  }

  Widget _phaseChip(
    BuildContext context, {
    required String label,
    required String? value,
  }) {
    final isSelected = _phaseFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _phaseFilter = value),
    );
  }

  void _showCreateSheet(BuildContext context) {
    // Placeholder — full activity creation form needs status/subtype pickers.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity creation coming soon')),
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
