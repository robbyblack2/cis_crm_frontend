import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/contacts/data/datasources/contact_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/models/contact_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ContactRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = ContactRemoteDataSourceImpl(dio: mockDio);
  });

  final tContactJson = <String, dynamic>{
    'id': '1',
    'owner_id': null,
    'company_id': null,
    'first_name': 'John',
    'last_name': 'Doe',
    'email': 'john@example.com',
    'phone': null,
    'job_title': null,
    'source': null,
    'status': 'active',
    'tags': <String>['vip'],
    'created_at': '2024-01-01T00:00:00.000',
    'updated_at': '2024-01-01T00:00:00.000',
  };

  group('getContacts', () {
    test('returns list of ContactModel when response is 200', () async {
      when(() => mockDio.get<List<dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: [tContactJson],
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.getContacts();

      expect(result, isA<List<ContactModel>>());
      expect(result, hasLength(1));
      expect(result.first.firstName, equals('John'));
      verify(() => mockDio.get<List<dynamic>>('/api/contacts')).called(1);
    });

    test('throws ServerException when response data is null', () async {
      when(() => mockDio.get<List<dynamic>>(any())).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      expect(
        () => dataSource.getContacts(),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws NetworkException on connection error', () async {
      when(() => mockDio.get<List<dynamic>>(any())).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(),
        ),
      );

      expect(
        () => dataSource.getContacts(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws UnauthorizedException on 401 response', () async {
      when(() => mockDio.get<List<dynamic>>(any())).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ),
      );

      expect(
        () => dataSource.getContacts(),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('throws ServerException on 500 response', () async {
      when(() => mockDio.get<List<dynamic>>(any())).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          message: 'Internal Server Error',
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ),
      );

      expect(
        () => dataSource.getContacts(),
        throwsA(
          isA<ServerException>().having(
            (e) => e.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });
  });

  group('getContact', () {
    test('returns ContactModel when response is 200', () async {
      when(() => mockDio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: tContactJson,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await dataSource.getContact('1');

      expect(result, isA<ContactModel>());
      expect(result.id, equals('1'));
      verify(() => mockDio.get<Map<String, dynamic>>('/api/contacts/1'))
          .called(1);
    });
  });
}
