import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:cis_crm/features/activity/presentation/bloc/calendar_activities_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Activity type colors matching the issue spec.
class ActivityColors {
  static const meeting = Color(0xFFA855F7);
  static const task = Color(0xFF3B82F6);
  static const call = Color(0xFF22C55E);

  static Color forType(ActivityType type) => switch (type) {
        ActivityType.meeting => meeting,
        ActivityType.task => task,
        ActivityType.call => call,
      };
}

/// Full-width Google Calendar-style month grid.
class ActivitiesCalendarView extends StatefulWidget {
  const ActivitiesCalendarView({
    super.key,
    this.onDaySelected,
    this.onActivityTap,
  });

  final ValueChanged<DateTime>? onDaySelected;
  final ValueChanged<Activity>? onActivityTap;

  @override
  State<ActivitiesCalendarView> createState() => _ActivitiesCalendarViewState();
}

class _ActivitiesCalendarViewState extends State<ActivitiesCalendarView> {
  final _focusNode = FocusNode();

  static const _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _goToPreviousMonth(CalendarActivitiesBloc bloc) {
    final current = bloc.state.focusedMonth;
    final prev = DateTime(current.year, current.month - 1);
    bloc.add(CalendarMonthRequested(month: prev));
  }

  void _goToNextMonth(CalendarActivitiesBloc bloc) {
    final current = bloc.state.focusedMonth;
    final next = DateTime(current.year, current.month + 1);
    bloc.add(CalendarMonthRequested(month: next));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<CalendarActivitiesBloc>();
    final state = bloc.state;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _goToPreviousMonth(bloc);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _goToNextMonth(bloc);
          }
        }
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -200) {
            _goToNextMonth(bloc);
          } else if (details.primaryVelocity! > 200) {
            _goToPreviousMonth(bloc);
          }
        },
        child: Column(
          children: [
            // ── Month Navigation Header ──
            _MonthHeader(
              focusedMonth: state.focusedMonth,
              isLoading: state.isLoading,
              onPrevious: () => _goToPreviousMonth(bloc),
              onNext: () => _goToNextMonth(bloc),
              onToday: () => bloc.add(const CalendarTodayRequested()),
              onMonthYearTap: () => _showMonthPicker(context, bloc),
            ),
            const SizedBox(height: 4),
            // ── Week Day Headers ──
            _WeekDayHeaders(weekDays: _weekDays),
            const Divider(height: 1),
            // ── Month Grid ──
            Expanded(
              child: _MonthGrid(
                focusedMonth: state.focusedMonth,
                selectedDay: state.selectedDay,
                activitiesForDay: state.activitiesForDay,
                onDaySelected: (day) {
                  bloc.add(CalendarDaySelected(day: day));
                  widget.onDaySelected?.call(day);
                },
                onActivityTap: widget.onActivityTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMonthPicker(
    BuildContext context,
    CalendarActivitiesBloc bloc,
  ) async {
    final current = bloc.state.focusedMonth;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      final month = DateTime(picked.year, picked.month);
      bloc.add(CalendarMonthRequested(month: month));
      bloc.add(CalendarDaySelected(day: picked));
    }
  }
}

// ── Month Header ──

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.focusedMonth,
    required this.isLoading,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onMonthYearTap,
  });

  final DateTime focusedMonth;
  final bool isLoading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onMonthYearTap;

  static final _monthYearFmt = DateFormat('MMMM yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
            tooltip: 'Previous month',
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onMonthYearTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _monthYearFmt.format(focusedMonth),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
            tooltip: 'Next month',
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: onToday,
            child: const Text('Today'),
          ),
          if (isLoading) ...[
            const SizedBox(width: 12),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Week Day Headers ──

class _WeekDayHeaders extends StatelessWidget {
  const _WeekDayHeaders({required this.weekDays});

  final List<String> weekDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: weekDays
          .map((d) => Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ── Month Grid ──

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.focusedMonth,
    required this.selectedDay,
    required this.activitiesForDay,
    required this.onDaySelected,
    this.onActivityTap,
  });

  final DateTime focusedMonth;
  final DateTime selectedDay;
  final List<Activity> Function(DateTime) activitiesForDay;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<Activity>? onActivityTap;

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeks(focusedMonth);

    return Column(
      children: weeks
          .map((week) => Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: week.map((day) {
                    final isCurrentMonth = day.month == focusedMonth.month &&
                        day.year == focusedMonth.year;
                    final now = DateTime.now();
                    final isToday = day.year == now.year &&
                        day.month == now.month &&
                        day.day == now.day;
                    final isSelected = day.year == selectedDay.year &&
                        day.month == selectedDay.month &&
                        day.day == selectedDay.day;
                    final activities = activitiesForDay(day);

                    return Expanded(
                      child: _DayCell(
                        day: day,
                        isCurrentMonth: isCurrentMonth,
                        isToday: isToday,
                        isSelected: isSelected,
                        activities: activities,
                        onTap: () => onDaySelected(day),
                        onActivityTap: onActivityTap,
                      ),
                    );
                  }).toList(),
                ),
              ))
          .toList(),
    );
  }

  /// Builds a list of weeks (each week = list of 7 days) covering the month.
  List<List<DateTime>> _buildWeeks(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    // Monday = 1, so offset = (weekday - 1).
    final startOffset = (first.weekday - 1) % 7;
    final startDate = first.subtract(Duration(days: startOffset));

    final weeks = <List<DateTime>>[];
    var current = startDate;
    // Always show 6 rows for consistent grid height.
    for (var w = 0; w < 6; w++) {
      final week = <DateTime>[];
      for (var d = 0; d < 7; d++) {
        week.add(current);
        current = current.add(const Duration(days: 1));
      }
      weeks.add(week);
    }
    return weeks;
  }
}

// ── Day Cell ──

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.activities,
    required this.onTap,
    this.onActivityTap,
  });

  final DateTime day;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final List<Activity> activities;
  final VoidCallback onTap;
  final ValueChanged<Activity>? onActivityTap;

  static const _maxVisible = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
            bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          color: isSelected
              ? cs.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day number
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: isToday
                    ? BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Text(
                  '${day.day}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isToday
                        ? cs.onPrimary
                        : isCurrentMonth
                            ? cs.onSurface
                            : cs.onSurface.withValues(alpha: 0.35),
                    fontWeight:
                        isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
            // Activity pills
            ...activities.take(_maxVisible).map((a) => _ActivityPill(
                  activity: a,
                  onTap: onActivityTap != null ? () => onActivityTap!(a) : null,
                )),
            if (activities.length > _maxVisible)
              Padding(
                padding: const EdgeInsets.only(left: 2, top: 1),
                child: Text(
                  '+${activities.length - _maxVisible} more',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Activity Pill ──

class _ActivityPill extends StatelessWidget {
  const _ActivityPill({
    required this.activity,
    this.onTap,
  });

  final Activity activity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = ActivityColors.forType(activity.activityType);

    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Text(
            activity.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
