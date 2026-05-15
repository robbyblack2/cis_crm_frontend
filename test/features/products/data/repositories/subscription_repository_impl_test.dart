import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/features/products/data/datasources/subscription_remote_datasource.dart';
import 'package:cis_crm/features/products/data/models/line_item_model.dart';
import 'package:cis_crm/features/products/data/models/subscription_model.dart';
import 'package:cis_crm/features/products/data/repositories/subscription_repository_impl.dart';
import 'package:cis_crm/features/products/domain/entities/subscription_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubscriptionRemoteDatasource extends Mock
    implements SubscriptionRemoteDatasource {}

void main() {
  late MockSubscriptionRemoteDatasource mockDatasource;
  late SubscriptionRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockSubscriptionRemoteDatasource();
    repository = SubscriptionRepositoryImpl(datasource: mockDatasource);
  });

  final tModel = SubscriptionModel(
    id: 's1',
    companyId: 'c1',
    systemId: 'sys1',
    productType: 'monitoring',
    status: SubscriptionStatus.active,
    tags: const [],
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  final tLineItem = LineItemModel(
    id: 'li1',
    productId: 'p1',
    parentType: 'subscription',
    parentId: 's1',
    quantity: 2,
    unitPrice: 50,
    createdAt: DateTime(2024),
  );

  group('getSubscriptions', () {
    test('returns Success when datasource succeeds', () async {
      when(() => mockDatasource.getSubscriptions())
          .thenAnswer((_) async => [tModel]);

      final result = await repository.getSubscriptions();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, [tModel]);
    });

    test('returns Failure when datasource throws ServerException', () async {
      when(() => mockDatasource.getSubscriptions())
          .thenThrow(const ServerException('fail'));

      final result = await repository.getSubscriptions();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('getSubscription', () {
    test('returns Success when datasource succeeds', () async {
      when(() => mockDatasource.getSubscription(any()))
          .thenAnswer((_) async => tModel);

      final result = await repository.getSubscription(id: 's1');

      expect(result.isSuccess, isTrue);
    });

    test('returns Failure when datasource throws', () async {
      when(() => mockDatasource.getSubscription(any()))
          .thenThrow(const ServerException('not found', statusCode: 404));

      final result = await repository.getSubscription(id: 's1');

      expect(result.isFailure, isTrue);
    });
  });

  group('getLineItems', () {
    test('returns Success with line items when datasource succeeds', () async {
      when(() => mockDatasource.getLineItems(any()))
          .thenAnswer((_) async => [tLineItem]);

      final result = await repository.getLineItems(subscriptionId: 's1');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, [tLineItem]);
    });

    test('returns Failure when datasource throws', () async {
      when(() => mockDatasource.getLineItems(any()))
          .thenThrow(const ServerException('fail'));

      final result = await repository.getLineItems(subscriptionId: 's1');

      expect(result.isFailure, isTrue);
    });
  });

  group('addLineItem', () {
    test('returns Success when datasource succeeds', () async {
      when(() => mockDatasource.addLineItem(any(), any()))
          .thenAnswer((_) async => tLineItem);

      final result = await repository.addLineItem(
        subscriptionId: 's1',
        productId: 'p1',
        quantity: 2,
        unitPrice: 50,
      );

      expect(result.isSuccess, isTrue);
    });

    test('returns Failure when datasource throws', () async {
      when(() => mockDatasource.addLineItem(any(), any()))
          .thenThrow(const ServerException('fail'));

      final result = await repository.addLineItem(
        subscriptionId: 's1',
        productId: 'p1',
        quantity: 2,
        unitPrice: 50,
      );

      expect(result.isFailure, isTrue);
    });
  });
}
