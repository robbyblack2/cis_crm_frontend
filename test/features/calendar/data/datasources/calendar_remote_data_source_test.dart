import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/calendar/data/datasources/calendar_remote_data_source.dart';
import 'package:cis_crm/features/calendar/data/models/calendar_event_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late CalendarRemoteDataSourceImpl dataSource;

  final tEventJson = <String, dynamic>{
    'id': '1',
    'title': 'Test Event',
    'start': '2026-05-15T10:00:00.000',
    'end': '2026-05-15T11:00:00.000',
    'created_at': '2026-05-15T00:00:00.000',
    'google_event_id': null,
    'location': null,
    'meeting_link': null,
    'linked_record_id': null,
  };

  setUp(() {
    mockDio = MockDio();
    dataSource = CalendarRemoteDataSourceImpl(dio: mockDio);
  });

  group('getEvents', () {
    test('returns list of CalendarEventModel on success', () async {
      when(() => mockDio.get<List<dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: [tEventJson],
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.getEvents();

      expect(result, isA<List<CalendarEventModel>>());
      expect(result, hasLength(1));
      expect(result.first.id, '1');
      expect(result.first.title, 'Test Event');
    });

    test('throws ServerException on null response data', () async {
      when(() => mockDio.get<List<dynamic>>(any())).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(),
        ),
      );

      expect(
        () => dataSource.getEvents(),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws ServerException on DioException', () async {
      when(() => mockDio.get<List<dynamic>>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response<dynamic>(
            statusCode: 500,
            requestOptions: RequestOptions(),
          ),
        ),
      );

      expect(
        () => dataSource.getEvents(),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('createEvent', () {
    test('returns CalendarEventModel on success', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: tEventJson,
          statusCode: 201,
          requestOptions: RequestOptions(),
        ),
      );

      final model = CalendarEventModel(
        id: '1',
        title: 'Test Event',
        start: DateTime(2026, 5, 15, 10),
        end: DateTime(2026, 5, 15, 11),
        createdAt: DateTime(2026, 5, 15),
      );

      final result = await dataSource.createEvent(model);

      expect(result, isA<CalendarEventModel>());
      expect(result.id, '1');
    });

    test('throws ServerException on DioException', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(requestOptions: RequestOptions()),
      );

      final model = CalendarEventModel(
        id: '1',
        title: 'Test Event',
        start: DateTime(2026, 5, 15, 10),
        end: DateTime(2026, 5, 15, 11),
        createdAt: DateTime(2026, 5, 15),
      );

      expect(
        () => dataSource.createEvent(model),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('deleteEvent', () {
    test('completes successfully on 200', () async {
      when(() => mockDio.delete<void>(any())).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      await expectLater(dataSource.deleteEvent('1'), completes);
    });

    test('throws ServerException on DioException', () async {
      when(() => mockDio.delete<void>(any())).thenThrow(
        DioException(requestOptions: RequestOptions()),
      );

      expect(
        () => dataSource.deleteEvent('1'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
