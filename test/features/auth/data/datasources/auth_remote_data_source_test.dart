import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:cis_crm/features/auth/data/models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = _MockDio();
    dataSource = AuthRemoteDataSourceImpl(dio);
  });

  setUpAll(() {
    registerFallbackValue(RequestOptions());
  });

  const userJson = {
    'id': '1',
    'email': 'test@example.com',
    'display_name': 'Test User',
    'status': 'active',
  };

  group('signIn', () {
    test('returns access token on successful login', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'data': {'access_token': 'test-jwt-token'},
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/auth/login'),
        ),
      );

      final result = await dataSource.signIn(
        email: 'test@example.com',
        password: 'password',
      );

      expect(result, isA<String>());
      expect(result, 'test-jwt-token');
    });

    test('throws UnauthorizedException on 401', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/api/auth/login'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => dataSource.signIn(
          email: 'test@example.com',
          password: 'wrong',
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('throws NetworkException on connection error', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => dataSource.signIn(
          email: 'test@example.com',
          password: 'password',
        ),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws ServerException on other errors', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/api/auth/login'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => dataSource.signIn(
          email: 'test@example.com',
          password: 'password',
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('signOut', () {
    test('completes on success', () async {
      when(
        () => dio.post<void>(any()),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/auth/logout'),
        ),
      );

      await expectLater(dataSource.signOut(), completes);
    });
  });

  group('currentUser', () {
    test('returns UserModel on success', () async {
      when(
        () => dio.get<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (_) async => Response(
          data: {'data': userJson},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/auth/me'),
        ),
      );

      final result = await dataSource.currentUser();

      expect(result, isA<UserModel>());
      expect(result.id, '1');
    });

    test('throws UnauthorizedException on 401', () async {
      when(
        () => dio.get<Map<String, dynamic>>(any()),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/me'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/api/auth/me'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => dataSource.currentUser(),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });
}
