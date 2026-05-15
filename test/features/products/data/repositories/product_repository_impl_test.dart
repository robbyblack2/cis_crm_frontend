import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/features/products/data/datasources/product_remote_datasource.dart';
import 'package:cis_crm/features/products/data/models/product_model.dart';
import 'package:cis_crm/features/products/data/repositories/product_repository_impl.dart';
import 'package:cis_crm/features/products/domain/entities/product_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRemoteDatasource extends Mock
    implements ProductRemoteDatasource {}

void main() {
  late MockProductRemoteDatasource mockDatasource;
  late ProductRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockProductRemoteDatasource();
    repository = ProductRepositoryImpl(datasource: mockDatasource);
  });

  final tModel = ProductModel(
    id: '1',
    name: 'Widget',
    type: ProductType.hardware,
    defaultPrice: 10,
    currency: 'USD',
    isActive: true,
    tags: const [],
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  group('getProducts', () {
    test('returns Success with list when datasource succeeds', () async {
      when(() => mockDatasource.getProducts())
          .thenAnswer((_) async => [tModel]);

      final result = await repository.getProducts();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, [tModel]);
    });

    test(
        'returns Failure(ServerFailure) when datasource throws '
        'ServerException', () async {
      when(() => mockDatasource.getProducts())
          .thenThrow(const ServerException('fail', statusCode: 500));

      final result = await repository.getProducts();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test(
        'returns Failure(NetworkFailure) when datasource throws '
        'NetworkException', () async {
      when(() => mockDatasource.getProducts())
          .thenThrow(const NetworkException());

      final result = await repository.getProducts();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('createProduct', () {
    test('returns Success when datasource succeeds', () async {
      when(() => mockDatasource.createProduct(any()))
          .thenAnswer((_) async => tModel);

      final result = await repository.createProduct(
        name: 'Widget',
        type: 'hardware',
        currency: 'USD',
      );

      expect(result.isSuccess, isTrue);
    });

    test('returns Failure when datasource throws', () async {
      when(() => mockDatasource.createProduct(any()))
          .thenThrow(const ServerException('fail'));

      final result = await repository.createProduct(
        name: 'Widget',
        type: 'hardware',
        currency: 'USD',
      );

      expect(result.isFailure, isTrue);
    });
  });

  group('deleteProduct', () {
    test('returns Success(null) when datasource succeeds', () async {
      when(() => mockDatasource.deleteProduct(any())).thenAnswer((_) async {});

      final result = await repository.deleteProduct(id: '1');

      expect(result.isSuccess, isTrue);
    });

    test('returns Failure when datasource throws', () async {
      when(() => mockDatasource.deleteProduct(any()))
          .thenThrow(const ServerException('fail'));

      final result = await repository.deleteProduct(id: '1');

      expect(result.isFailure, isTrue);
    });
  });
}
