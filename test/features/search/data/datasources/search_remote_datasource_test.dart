import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/search/data/datasources/search_remote_datasource.dart';
import 'package:cis_crm/features/search/data/models/search_result_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late SearchRemoteDatasourceImpl datasource;

  setUp(() {
    mockDio = MockDio();
    datasource = SearchRemoteDatasourceImpl(dio: mockDio);
  });

  final tResponseData = [
    {
      'id': '1',
      'entity_type': 'contact',
      'title': 'John Doe',
      'subtitle': 'john@example.com',
      'matched_field': 'name',
    },
  ];

  group('search', () {
    test('returns List<SearchResultModel> when the call is successful',
        () async {
      when(
        () => mockDio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: tResponseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final results = await datasource.search(query: 'john');

      expect(results, isA<List<SearchResultModel>>());
      expect(results.length, 1);
      expect(results.first.id, '1');
      expect(results.first.entityType, 'contact');
      verify(
        () => mockDio.get<List<dynamic>>(
          '/api/search',
          queryParameters: {'q': 'john'},
        ),
      ).called(1);
    });

    test('includes type in query parameters when provided', () async {
      when(
        () => mockDio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: tResponseData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      await datasource.search(query: 'john', type: 'contact');

      verify(
        () => mockDio.get<List<dynamic>>(
          '/api/search',
          queryParameters: {'q': 'john', 'type': 'contact'},
        ),
      ).called(1);
    });

    test('throws ServerException when DioException occurs', () async {
      when(
        () => mockDio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(),
          ),
          message: 'Internal Server Error',
        ),
      );

      expect(
        () => datasource.search(query: 'john'),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws ServerException when response data is null', () async {
      when(
        () => mockDio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<List<dynamic>>(
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      expect(
        () => datasource.search(query: 'john'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
