import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/calendar/domain/entities/calendar_event.dart';
import 'package:cis_crm/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cis_crm/features/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

void main() {
  late MockCalendarRepository mockRepository;

  final tEvent = CalendarEvent(
    id: '1',
    title: 'Test Event',
    start: DateTime(2026, 5, 15, 10),
    end: DateTime(2026, 5, 15, 11),
    createdAt: DateTime(2026, 5, 15),
  );

  final tEvents = [tEvent];

  setUp(() {
    mockRepository = MockCalendarRepository();
  });

  setUpAll(() {
    registerFallbackValue(
      CalendarEvent(
        id: '',
        title: '',
        start: DateTime(2026),
        end: DateTime(2026),
        createdAt: DateTime(2026),
      ),
    );
  });

  group('CalendarBloc', () {
    test('initial state is CalendarInitial', () {
      final bloc = CalendarBloc(repository: mockRepository);
      expect(bloc.state, const CalendarInitial());
      bloc.close();
    });

    group('CalendarLoadRequested', () {
      blocTest<CalendarBloc, CalendarState>(
        'emits [CalendarLoading, CalendarLoaded] on success',
        build: () {
          when(() => mockRepository.getEvents())
              .thenAnswer((_) async => Success(tEvents));
          return CalendarBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const CalendarLoadRequested()),
        expect: () => [
          const CalendarLoading(),
          CalendarLoaded(events: tEvents),
        ],
      );

      blocTest<CalendarBloc, CalendarState>(
        'emits [CalendarLoading, CalendarError] on failure',
        build: () {
          when(() => mockRepository.getEvents()).thenAnswer(
            (_) async =>
                const Failure(ServerFailure('Server error', statusCode: 500)),
          );
          return CalendarBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const CalendarLoadRequested()),
        expect: () => [
          const CalendarLoading(),
          const CalendarError(
            failure: ServerFailure('Server error', statusCode: 500),
          ),
        ],
      );
    });

    group('CalendarEventCreateRequested', () {
      blocTest<CalendarBloc, CalendarState>(
        'emits [CalendarLoading, CalendarLoaded] on success',
        build: () {
          when(() => mockRepository.createEvent(any()))
              .thenAnswer((_) async => Success(tEvent));
          when(() => mockRepository.getEvents())
              .thenAnswer((_) async => Success(tEvents));
          return CalendarBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(CalendarEventCreateRequested(event: tEvent)),
        expect: () => [
          const CalendarLoading(),
          CalendarLoaded(events: tEvents),
        ],
      );

      blocTest<CalendarBloc, CalendarState>(
        'emits [CalendarLoading, CalendarError] when create fails',
        build: () {
          when(() => mockRepository.createEvent(any())).thenAnswer(
            (_) async => const Failure(ServerFailure('Create failed')),
          );
          return CalendarBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(CalendarEventCreateRequested(event: tEvent)),
        expect: () => [
          const CalendarLoading(),
          const CalendarError(failure: ServerFailure('Create failed')),
        ],
      );
    });
  });
}
