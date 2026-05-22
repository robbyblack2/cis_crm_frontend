import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/data/models/activity_model.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:cis_crm/features/activity/domain/repositories/task_repository.dart';
import 'package:cis_crm/features/activity/presentation/bloc/calendar_activities_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements TaskRepository {}

final _may = DateTime(2026, 5);

final _activity = ActivityModel(
  id: 'a1',
  activityType: ActivityType.task,
  title: 'Task',
  statusId: 's',
  statusName: 'To Do',
  statusPhase: 'open',
  dueDate: '2026-05-15',
  createdAt: DateTime.utc(2026, 5, 10),
  updatedAt: DateTime.utc(2026, 5, 10),
);

void main() {
  late _MockRepo repo;

  void stubAll([Result<List<Activity>, AppFailure>? result]) {
    when(() => repo.getActivities()).thenAnswer(
        (_) async => result ?? const Success(<Activity>[]));
  }

  setUp(() {
    repo = _MockRepo();
    stubAll();
  });

  CalendarActivitiesBloc build() =>
      CalendarActivitiesBloc(repository: repo);

  group('CalendarDaySelected', () {
    blocTest<CalendarActivitiesBloc, CalendarActivitiesState>(
      'updates selectedDay',
      build: build,
      act: (b) => b.add(CalendarDaySelected(day: DateTime(2026, 5, 15))),
      expect: () => [
        isA<CalendarActivitiesState>()
            .having((s) => s.selectedDay.day, 'day', 15),
      ],
    );
  });

  group('selectedDayActivities', () {
    test('returns activities for selected day', () {
      final state = CalendarActivitiesState(
        focusedMonth: _may,
        selectedDay: DateTime(2026, 5, 15),
        activities: {
          '2026-05-15': [_activity],
        },
      );
      expect(state.selectedDayActivities, hasLength(1));
      expect(state.selectedDayActivities.first.id, 'a1');
    });

    test('returns empty for day with no activities', () {
      final state = CalendarActivitiesState(
        focusedMonth: _may,
        selectedDay: DateTime(2026, 5, 20),
      );
      expect(state.selectedDayActivities, isEmpty);
    });
  });

  group('activitiesForDay', () {
    test('returns correct activities for a given day', () {
      final state = CalendarActivitiesState(
        focusedMonth: _may,
        selectedDay: DateTime(2026, 5, 1),
        activities: {
          '2026-05-15': [_activity],
        },
      );
      expect(state.activitiesForDay(DateTime(2026, 5, 15)), hasLength(1));
      expect(state.activitiesForDay(DateTime(2026, 5, 16)), isEmpty);
    });
  });

  group('CalendarMonthRequested', () {
    blocTest<CalendarActivitiesBloc, CalendarActivitiesState>(
      'sets focusedMonth and fetches activities',
      build: () {
        stubAll(Success([_activity]));
        return build();
      },
      act: (b) => b.add(CalendarMonthRequested(month: _may)),
      wait: const Duration(seconds: 2),
      verify: (b) {
        expect(b.state.focusedMonth, DateTime(2026, 5));
        expect(b.state.activities['2026-05-15'], isNotEmpty);
        expect(b.state.isLoading, isFalse);
      },
    );

    blocTest<CalendarActivitiesBloc, CalendarActivitiesState>(
      'fetches without date filters so meetings with start_time are included',
      build: () {
        stubAll(Success([_activity]));
        return build();
      },
      act: (b) => b.add(CalendarMonthRequested(month: _may)),
      wait: const Duration(seconds: 2),
      verify: (_) {
        // Uses the same getActivities() as the working list view
        verify(() => repo.getActivities())
            .called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<CalendarActivitiesBloc, CalendarActivitiesState>(
      'emits error on failure',
      build: () {
        stubAll(const Failure(ServerFailure('fail')));
        return build();
      },
      act: (b) => b.add(CalendarMonthRequested(month: _may)),
      wait: const Duration(seconds: 2),
      verify: (b) {
        expect(b.state.errorMessage, 'fail');
        expect(b.state.isLoading, isFalse);
      },
    );
  });

  group('CalendarTodayRequested', () {
    blocTest<CalendarActivitiesBloc, CalendarActivitiesState>(
      'sets focusedMonth and selectedDay to today',
      build: build,
      act: (b) => b.add(const CalendarTodayRequested()),
      wait: const Duration(seconds: 2),
      verify: (b) {
        final now = DateTime.now();
        expect(b.state.focusedMonth.year, now.year);
        expect(b.state.focusedMonth.month, now.month);
        expect(b.state.selectedDay.day, now.day);
      },
    );
  });

  group('CalendarRefreshRequested', () {
    blocTest<CalendarActivitiesBloc, CalendarActivitiesState>(
      'clears activities and re-fetches for current month',
      build: () {
        stubAll(Success([_activity]));
        return build();
      },
      seed: () => CalendarActivitiesState(
        focusedMonth: _may,
        selectedDay: DateTime(2026, 5, 15),
        activities: {
          '2026-05-15': [_activity],
        },
      ),
      act: (b) => b.add(const CalendarRefreshRequested()),
      wait: const Duration(seconds: 2),
      verify: (b) {
        // Should have re-fetched and re-populated
        expect(b.state.isLoading, isFalse);
        expect(b.state.activities['2026-05-15'], isNotEmpty);
        expect(b.state.focusedMonth, _may);
      },
    );
  });

  group('Prefetch behavior', () {
    blocTest<CalendarActivitiesBloc, CalendarActivitiesState>(
      'prefetch does not change focusedMonth',
      build: build,
      act: (b) => b.add(CalendarMonthRequested(month: _may)),
      wait: const Duration(seconds: 2),
      verify: (b) {
        // After loading May + prefetching Apr/Jun, focused month stays May.
        expect(b.state.focusedMonth, DateTime(2026, 5));
      },
    );
  });

  group('copyWith', () {
    test('creates a copy with updated fields', () {
      final original = CalendarActivitiesState(
        focusedMonth: _may,
        selectedDay: DateTime(2026, 5, 1),
      );
      final updated = original.copyWith(
        selectedDay: DateTime(2026, 5, 15),
        isLoading: true,
      );
      expect(updated.selectedDay.day, 15);
      expect(updated.isLoading, isTrue);
      expect(updated.focusedMonth, _may);
    });

    test('errorMessage can be set to null via factory', () {
      final state = CalendarActivitiesState(
        focusedMonth: _may,
        selectedDay: DateTime(2026, 5, 1),
        errorMessage: 'old error',
      );
      final cleared = state.copyWith(errorMessage: () => null);
      expect(cleared.errorMessage, isNull);
    });
  });
}
