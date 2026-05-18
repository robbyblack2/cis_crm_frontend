import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/products/data/datasources/product_remote_datasource.dart';
import 'package:cis_crm/features/products/data/models/product_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ProductRemoteDatasourceImpl datasource;

  setUp(() {
    mockDio = MockDio();
    datasource = ProductRemoteDatasourceImpl(dio: mockDio);
  });

  group('getProducts', () {
    test('returns list of ProductModel when response is 200', () async {
      when(() => mockDio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{
            'data': <dynamic>[
              <String, dynamic>{
                'id': '1',
                'name': 'Widget',
                'type': 'hardware',
                'default_price': 10.0,
                'currency': 'USD',
                'is_active': true,
                'tags': <String>[],
                'created_at': '2024-01-01T00:00:00.000',
                'updated_at': '2024-01-01T00:00:00.000',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await datasource.getProducts();

      expect(result, isA<List<ProductModel>>());
      expect(result.length, 1);
      expect(result.first.name, 'Widget');
    });

    test('throws ServerException when DioException occurs', () async {
      when(() => mockDio.get<Map<String, dynamic>>(any())).thenThrow(
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
        () => datasource.getProducts(),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('createProduct', () {
    test('returns ProductModel when response is 201', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'id': '2',
              'name': 'New',
              'type': 'service',
              'default_price': null,
              'currency': 'USD',
              'is_active': true,
              'tags': <String>[],
              'created_at': '2024-01-01T00:00:00.000',
              'updated_at': '2024-01-01T00:00:00.000',
            },
          },
          statusCode: 201,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await datasource.createProduct({'name': 'New'});

      expect(result, isA<ProductModel>());
      expect(result.name, 'New');
    });
  });

  group('deleteProduct', () {
    test('completes without error when response is 204', () async {
      when(() => mockDio.delete<void>(any())).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(),
        ),
      );

      await expectLater(
        datasource.deleteProduct('1'),
        completes,
      );
    });

    test('throws ServerException when DioException occurs', () async {
      when(() => mockDio.delete<void>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          message: 'Not found',
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(),
          ),
        ),
      );

      expect(
        () => datasource.deleteProduct('1'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
