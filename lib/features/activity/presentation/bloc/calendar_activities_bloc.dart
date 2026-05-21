import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:cis_crm/features/activity/domain/repositories/calendar_activity_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// ── Events ──────────────────────────────────────────────────────────────

@immutable
sealed class CalendarActivitiesEvent extends Equatable {
  const CalendarActivitiesEvent();

  @override
  List<Object?> get props => [];
}

/// User navigated to a specific month — updates focusedMonth + fetches data.
final class CalendarMonthRequested extends CalendarActivitiesEvent {
  const CalendarMonthRequested({required this.month});

  final DateTime month;

  @override
  List<Object?> get props => [month];
}

/// Background prefetch — loads data for a month WITHOUT changing focusedMonth.
final class _CalendarPrefetchRequested extends CalendarActivitiesEvent {
  const _CalendarPrefetchRequested({required this.month});

  final DateTime month;

  @override
  List<Object?> get props => [month];
}

final class CalendarDaySelected extends CalendarActivitiesEvent {
  const CalendarDaySelected({required this.day});

  final DateTime day;

  @override
  List<Object?> get props => [day];
}

final class CalendarTodayRequested extends CalendarActivitiesEvent {
  const CalendarTodayRequested();
}

// ── State ───────────────────────────────────────────────────────────────

@immutable
class CalendarActivitiesState extends Equatable {
  const CalendarActivitiesState({
    required this.focusedMonth,
    required this.selectedDay,
    this.activities = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  final DateTime focusedMonth;
  final DateTime selectedDay;
  final Map<String, List<Activity>> activities;
  final bool isLoading;
  final String? errorMessage;

  List<Activity> get selectedDayActivities {
    final key = DateFormat('yyyy-MM-dd').format(selectedDay);
    return activities[key] ?? const [];
  }

  List<Activity> activitiesForDay(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    return activities[key] ?? const [];
  }

  CalendarActivitiesState copyWith({
    DateTime? focusedMonth,
    DateTime? selectedDay,
    Map<String, List<Activity>>? activities,
    bool? isLoading,
    String? Function()? errorMessage,
  }) {
    return CalendarActivitiesState(
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDay: selectedDay ?? this.selectedDay,
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        focusedMonth,
        selectedDay,
        activities,
        isLoading,
        errorMessage,
      ];
}

// ── Bloc ────────────────────────────────────────────────────────────────

class CalendarActivitiesBloc
    extends Bloc<CalendarActivitiesEvent, CalendarActivitiesState> {
  CalendarActivitiesBloc({
    required CalendarActivityRepository repository,
  })  : _repository = repository,
        super(CalendarActivitiesState(
          focusedMonth: DateTime(DateTime.now().year, DateTime.now().month),
          selectedDay: DateTime.now(),
        )) {
    on<CalendarMonthRequested>(_onMonthRequested, transformer: restartable());
    on<_CalendarPrefetchRequested>(_onPrefetch, transformer: concurrent());
    on<CalendarDaySelected>(_onDaySelected);
    on<CalendarTodayRequested>(_onTodayRequested);
  }

  final CalendarActivityRepository _repository;
  final Set<String> _fetchedMonths = {};
  final Set<String> _failedMonths = {};
  static final _dateFmt = DateFormat('yyyy-MM-dd');

  /// User-initiated month navigation — changes focusedMonth, then fetches.
  Future<void> _onMonthRequested(
    CalendarMonthRequested event,
    Emitter<CalendarActivitiesState> emit,
  ) async {
    final month = DateTime(event.month.year, event.month.month);
    final monthKey = DateFormat('yyyy-MM').format(month);

    // Always update focusedMonth for user-initiated navigation.
    emit(state.copyWith(
      focusedMonth: month,
      errorMessage: () => null,
    ));

    if (_fetchedMonths.contains(monthKey)) {
      _prefetchAdjacent(month);
      return;
    }

    await _fetchMonth(month, monthKey, emit);
  }

  /// Background prefetch — loads data but does NOT change focusedMonth.
  Future<void> _onPrefetch(
    _CalendarPrefetchRequested event,
    Emitter<CalendarActivitiesState> emit,
  ) async {
    final month = DateTime(event.month.year, event.month.month);
    final monthKey = DateFormat('yyyy-MM').format(month);

    if (_fetchedMonths.contains(monthKey)) return;
    if (_failedMonths.contains(monthKey)) return;

    await _fetchMonth(month, monthKey, emit);
  }

  Future<void> _fetchMonth(
    DateTime month,
    String monthKey,
    Emitter<CalendarActivitiesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final from = _dateFmt.format(month);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final to = _dateFmt.format(lastDay);

    final result = await _repository.getActivities(from: from, to: to);

    switch (result) {
      case Success(:final data):
        _fetchedMonths.add(monthKey);
        _failedMonths.remove(monthKey);
        final updated = Map<String, List<Activity>>.from(state.activities);
        for (final activity in data) {
          if (activity.dueDate != null) {
            final key = activity.dueDate!;
            updated.putIfAbsent(key, () => []).add(activity);
          }
        }
        emit(state.copyWith(
          activities: updated,
          isLoading: false,
          errorMessage: () => null,
        ));
        _prefetchAdjacent(month);
      case Failure(:final error):
        // Mark as failed so prefetch doesn't retry infinitely.
        _failedMonths.add(monthKey);
        emit(state.copyWith(
          isLoading: false,
          errorMessage: () => error.message,
        ));
    }
  }

  void _onDaySelected(
    CalendarDaySelected event,
    Emitter<CalendarActivitiesState> emit,
  ) {
    emit(state.copyWith(selectedDay: event.day));
  }

  void _onTodayRequested(
    CalendarTodayRequested event,
    Emitter<CalendarActivitiesState> emit,
  ) {
    final today = DateTime.now();
    final month = DateTime(today.year, today.month);
    emit(state.copyWith(
      focusedMonth: month,
      selectedDay: today,
    ));
    add(CalendarMonthRequested(month: month));
  }

  /// Prefetch adjacent months in the background — does NOT change focusedMonth.
  void _prefetchAdjacent(DateTime month) {
    final prev = DateTime(month.year, month.month - 1);
    final next = DateTime(month.year, month.month + 1);
    final prevKey = DateFormat('yyyy-MM').format(prev);
    final nextKey = DateFormat('yyyy-MM').format(next);

    if (!_fetchedMonths.contains(prevKey) && !_failedMonths.contains(prevKey)) {
      add(_CalendarPrefetchRequested(month: prev));
    }
    if (!_fetchedMonths.contains(nextKey) && !_failedMonths.contains(nextKey)) {
      add(_CalendarPrefetchRequested(month: next));
    }
  }
}
