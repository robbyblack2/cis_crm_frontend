import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/features/calendar/data/datasources/calendar_remote_data_source.dart';
import 'package:cis_crm/features/calendar/data/models/calendar_event_model.dart';
import 'package:cis_crm/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCalendarRemoteDataSource extends Mock
    implements CalendarRemoteDataSource {}

void main() {
  late MockCalendarRemoteDataSource mockDataSource;
  late CalendarRepositoryImpl repository;

  final tModel = CalendarEventModel(
    id: '1',
    title: 'Test Event',
    start: DateTime(2026, 5, 15, 10),
    end: DateTime(2026, 5, 15, 11),
    createdAt: DateTime(2026, 5, 15),
  );

  final tModels = [tModel];

  setUp(() {
    mockDataSource = MockCalendarRemoteDataSource();
    repository = CalendarRepositoryImpl(remoteDataSource: mockDataSource);
  });

  setUpAll(() {
    registerFallbackValue(
      CalendarEventModel(
        id: '',
        title: '',
        start: DateTime(2026),
        end: DateTime(2026),
        createdAt: DateTime(2026),
      ),
    );
  });

  group('getEvents', () {
    test('returns Success with events on success', () async {
      when(() => mockDataSource.getEvents()).thenAnswer((_) async => tModels);

      final result = await repository.getEvents();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, tModels);
    });

    test('returns Failure with ServerFailure on ServerException', () async {
      when(() => mockDataSource.getEvents())
          .thenThrow(const ServerException('Server error', statusCode: 500));

      final result = await repository.getEvents();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('returns Failure with NetworkFailure on NetworkException', () async {
      when(() => mockDataSource.getEvents())
          .thenThrow(const NetworkException());

      final result = await repository.getEvents();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('createEvent', () {
    test('returns Success with created event on success', () async {
      when(() => mockDataSource.createEvent(any()))
          .thenAnswer((_) async => tModel);

      final result = await repository.createEvent(tModel);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, tModel);
    });

    test('returns Failure on ServerException', () async {
      when(() => mockDataSource.createEvent(any()))
          .thenThrow(const ServerException('Create failed'));

      final result = await repository.createEvent(tModel);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('updateEvent', () {
    test('returns Success with updated event on success', () async {
      when(() => mockDataSource.updateEvent(any()))
          .thenAnswer((_) async => tModel);

      final result = await repository.updateEvent(tModel);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, tModel);
    });

    test('returns Failure on ServerException', () async {
      when(() => mockDataSource.updateEvent(any()))
          .thenThrow(const ServerException('Update failed'));

      final result = await repository.updateEvent(tModel);

      expect(result.isFailure, isTrue);
    });
  });

  group('deleteEvent', () {
    test('returns Success on successful delete', () async {
      when(() => mockDataSource.deleteEvent(any())).thenAnswer((_) async {});

      final result = await repository.deleteEvent('1');

      expect(result.isSuccess, isTrue);
    });

    test('returns Failure on ServerException', () async {
      when(() => mockDataSource.deleteEvent(any()))
          .thenThrow(const ServerException('Delete failed'));

      final result = await repository.deleteEvent('1');

      expect(result.isFailure, isTrue);
    });
  });
}
