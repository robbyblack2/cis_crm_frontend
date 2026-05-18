import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/settings/data/datasources/google_remote_data_source.dart';
import 'package:cis_crm/features/settings/data/models/google_connection_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late GoogleRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = GoogleRemoteDataSourceImpl(dio: mockDio);
  });

  group('getAuthUrl', () {
    test('returns auth URL string from GET /api/google/auth-url', () async {
      when(() => mockDio.get<Map<String, dynamic>>('/api/google/auth-url'))
          .thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{
            'data': {'auth_url': 'https://accounts.google.com/o/oauth2/auth'},
          },
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.getAuthUrl();

      expect(result, 'https://accounts.google.com/o/oauth2/auth');
    });

    test('throws ServerException when data is null', () async {
      when(() => mockDio.get<Map<String, dynamic>>('/api/google/auth-url'))
          .thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{'data': null},
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      expect(
        () => dataSource.getAuthUrl(),
        throwsA(isA<ServerException>()),
      );
    });

    test('rethrows DioException on network error', () async {
      when(() => mockDio.get<Map<String, dynamic>>('/api/google/auth-url'))
          .thenThrow(
        DioException(requestOptions: RequestOptions()),
      );

      expect(
        () => dataSource.getAuthUrl(),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('getStatus', () {
    test('returns GoogleConnectionModel from GET /api/google/status', () async {
      when(() => mockDio.get<Map<String, dynamic>>('/api/google/status'))
          .thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{
            'data': {
              'connected': true,
              'email': 'user@gmail.com',
              'last_sync': '2026-01-15T10:30:00Z',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.getStatus();

      expect(result, isA<GoogleConnectionModel>());
      expect(result.connected, isTrue);
      expect(result.email, 'user@gmail.com');
      expect(result.lastSync, isNotNull);
    });

    test('returns disconnected model when connected is false', () async {
      when(() => mockDio.get<Map<String, dynamic>>('/api/google/status'))
          .thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{
            'data': {
              'connected': false,
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.getStatus();

      expect(result.connected, isFalse);
      expect(result.email, isNull);
      expect(result.lastSync, isNull);
    });
  });

  group('disconnect', () {
    test('calls POST /api/google/disconnect', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>('/api/google/disconnect'),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(),
        ),
      );

      await dataSource.disconnect();

      verify(
        () => mockDio.post<Map<String, dynamic>>('/api/google/disconnect'),
      ).called(1);
    });

    test('rethrows DioException on error', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>('/api/google/disconnect'),
      ).thenThrow(
        DioException(requestOptions: RequestOptions()),
      );

      expect(
        () => dataSource.disconnect(),
        throwsA(isA<DioException>()),
      );
    });
  });
}
