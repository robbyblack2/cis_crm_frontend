import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/activity/data/datasources/activity_remote_data_source_impl.dart';
import 'package:cis_crm/features/activity/data/models/crm_task_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late MockDio mockDio;
  late ActivityRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    mockDio = MockDio();
    dataSource = ActivityRemoteDataSourceImpl(dio: mockDio);
  });

  group('getTasks', () {
    test('returns list of CrmTaskModel when response is 200', () async {
      final taskJson = <String, dynamic>{
        'id': '1',
        'title': 'Test',
        'status': 'todo',
        'priority': 'medium',
        'parent_type': 'contact',
        'parent_id': 'c1',
        'created_by': 'user1',
        'created_at': '2024-01-01T00:00:00.000',
        'updated_at': '2024-01-01T00:00:00.000',
      };
      when(() => mockDio.get<List<dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: [taskJson],
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.getTasks();
      expect(result, isA<List<CrmTaskModel>>());
      expect(result, hasLength(1));
      expect(result.first.title, 'Test');
    });

    test('throws ServerException on DioException', () async {
      when(() => mockDio.get<List<dynamic>>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          message: 'Network error',
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(),
          ),
        ),
      );

      expect(
        () => dataSource.getTasks(),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('deleteTask', () {
    test('completes without error on success', () async {
      when(() => mockDio.delete<void>(any())).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(),
        ),
      );

      await expectLater(dataSource.deleteTask('1'), completes);
    });

    test('throws ServerException on DioException', () async {
      when(() => mockDio.delete<void>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          message: 'fail',
        ),
      );

      expect(
        () => dataSource.deleteTask('1'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
