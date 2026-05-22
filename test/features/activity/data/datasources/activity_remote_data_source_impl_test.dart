import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/activity/data/datasources/activity_remote_data_source_impl.dart';
import 'package:cis_crm/features/activity/data/models/activity_model.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ActivityRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = ActivityRemoteDataSourceImpl(dio: mockDio);
  });

  final tJson = {
    'id': 'a1',
    'activity_type': 'task',
    'title': 'Test',
    'status_id': 's1',
    'status_name': 'To Do',
    'status_phase': 'open',
    'created_at': '2026-05-20T00:00:00Z',
    'updated_at': '2026-05-20T00:00:00Z',
  };

  group('getActivities', () {
    test('returns list on success', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {'data': [tJson]},
            statusCode: 200,
            requestOptions: RequestOptions(),
          ));

      final result = await dataSource.getActivities(from: '2026-05-01', to: '2026-05-31');
      expect(result, hasLength(1));
      expect(result.first.id, 'a1');
    });

    test('throws ServerException on DioException', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(requestOptions: RequestOptions()));

      expect(
        () => dataSource.getActivities(from: 'x', to: 'y'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('getActivity', () {
    test('returns ActivityModel on success', () async {
      when(() => mockDio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: {'data': tJson},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.getActivity('a1');
      expect(result.id, 'a1');
    });
  });

  group('createActivity', () {
    test('posts meetings to /api/calendar/events for Google push', () async {
      final meetingJson = {
        'id': 'm1',
        'activity_type': 'meeting',
        'title': 'Demo',
        'status_id': 's1',
        'status': {'id': 's1', 'name': 'Planned', 'phase': 'open'},
        'start_time': '2026-06-01T14:00:00Z',
        'end_time': '2026-06-01T14:30:00Z',
        'meeting_url': 'https://meet.google.com/abc',
        'created_at': '2026-05-20T00:00:00Z',
        'updated_at': '2026-05-20T00:00:00Z',
      };

      when(() => mockDio.post<Map<String, dynamic>>(
            '/api/calendar/events',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {'data': meetingJson},
            statusCode: 201,
            requestOptions: RequestOptions(),
          ));

      final meeting = ActivityModel(
        id: '',
        activityType: ActivityType.meeting,
        title: 'Demo',
        statusId: 's1',
        statusName: 'Planned',
        statusPhase: 'open',
        createdAt: DateTime.utc(2026, 5, 20),
        updatedAt: DateTime.utc(2026, 5, 20),
        startTime: DateTime.utc(2026, 6, 1, 14),
        endTime: DateTime.utc(2026, 6, 1, 14, 30),
        data: const {'create_meet_link': true},
      );

      final result = await dataSource.createActivity(meeting);

      expect(result.id, 'm1');
      expect(result.meetingUrl, 'https://meet.google.com/abc');
      verify(() => mockDio.post<Map<String, dynamic>>(
            '/api/calendar/events',
            data: any(named: 'data'),
          )).called(1);
    });

    test('posts tasks to /api/activities', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/api/activities',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {'data': tJson},
            statusCode: 201,
            requestOptions: RequestOptions(),
          ));

      final task = ActivityModel(
        id: '',
        activityType: ActivityType.task,
        title: 'Test',
        statusId: 's1',
        statusName: 'To Do',
        statusPhase: 'open',
        createdAt: DateTime.utc(2026, 5, 20),
        updatedAt: DateTime.utc(2026, 5, 20),
      );

      final result = await dataSource.createActivity(task);

      expect(result.id, 'a1');
      verify(() => mockDio.post<Map<String, dynamic>>(
            '/api/activities',
            data: any(named: 'data'),
          )).called(1);
    });
  });

  group('deleteActivity', () {
    test('completes on success', () async {
      when(() => mockDio.delete<void>(any())).thenAnswer(
        (_) async => Response(statusCode: 204, requestOptions: RequestOptions()),
      );
      await expectLater(dataSource.deleteActivity('a1'), completes);
    });

    test('throws ServerException on failure', () async {
      when(() => mockDio.delete<void>(any())).thenThrow(
        DioException(requestOptions: RequestOptions()),
      );
      expect(() => dataSource.deleteActivity('a1'), throwsA(isA<ServerException>()));
    });
  });
}
