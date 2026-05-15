import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/products/data/datasources/subscription_remote_datasource.dart';
import 'package:cis_crm/features/products/data/models/subscription_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late SubscriptionRemoteDatasourceImpl datasource;

  setUp(() {
    mockDio = MockDio();
    datasource = SubscriptionRemoteDatasourceImpl(dio: mockDio);
  });

  final tJson = <String, dynamic>{
    'id': 's1',
    'company_id': 'c1',
    'system_id': 'sys1',
    'product_type': 'monitoring',
    'status': 'active',
    'tags': <String>[],
    'created_at': '2024-01-01T00:00:00.000',
    'updated_at': '2024-01-01T00:00:00.000',
  };

  group('getSubscriptions', () {
    test('returns list of SubscriptionModel on success', () async {
      when(() => mockDio.get<List<dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: <dynamic>[tJson],
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await datasource.getSubscriptions();

      expect(result, isA<List<SubscriptionModel>>());
      expect(result.length, 1);
    });

    test('throws ServerException on DioException', () async {
      when(() => mockDio.get<List<dynamic>>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          message: 'fail',
        ),
      );

      expect(
        () => datasource.getSubscriptions(),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('getSubscription', () {
    test('returns SubscriptionModel on success', () async {
      when(() => mockDio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: tJson,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await datasource.getSubscription('s1');

      expect(result, isA<SubscriptionModel>());
      expect(result.id, 's1');
    });
  });

  group('getLineItems', () {
    test('returns list of LineItemModel on success', () async {
      when(() => mockDio.get<List<dynamic>>(any())).thenAnswer(
        (_) async => Response(
          data: <dynamic>[
            <String, dynamic>{
              'id': 'li1',
              'product_id': 'p1',
              'parent_type': 'subscription',
              'parent_id': 's1',
              'quantity': 2,
              'unit_price': 50.0,
              'serial_number': null,
              'start_date': null,
              'end_date': null,
              'created_at': '2024-01-01T00:00:00.000',
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final result = await datasource.getLineItems('s1');

      expect(result.length, 1);
      expect(result.first.productId, 'p1');
    });
  });

  group('deleteSubscription', () {
    test('completes without error on success', () async {
      when(() => mockDio.delete<void>(any())).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(),
        ),
      );

      await expectLater(
        datasource.deleteSubscription('s1'),
        completes,
      );
    });

    test('throws ServerException on DioException', () async {
      when(() => mockDio.delete<void>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          message: 'fail',
        ),
      );

      expect(
        () => datasource.deleteSubscription('s1'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
