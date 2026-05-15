import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/products/domain/entities/product.dart';
import 'package:cis_crm/features/products/domain/entities/product_type.dart';
import 'package:cis_crm/features/products/domain/repositories/product_repository.dart';
import 'package:cis_crm/features/products/presentation/bloc/products_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
  });

  final tProduct = Product(
    id: '1',
    name: 'Widget Pro',
    type: ProductType.hardware,
    defaultPrice: 99.99,
    currency: 'USD',
    isActive: true,
    tags: const ['electronics'],
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  group('ProductsBloc', () {
    blocTest<ProductsBloc, ProductsState>(
      'emits [Loading, Loaded] when ProductsLoadRequested succeeds',
      build: () {
        when(() => mockRepository.getProducts())
            .thenAnswer((_) async => Success([tProduct]));
        return ProductsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ProductsLoadRequested()),
      expect: () => [
        const ProductsLoading(),
        ProductsLoaded(products: [tProduct]),
      ],
    );

    blocTest<ProductsBloc, ProductsState>(
      'emits [Loading, Error] when ProductsLoadRequested fails',
      build: () {
        when(() => mockRepository.getProducts()).thenAnswer(
          (_) async => const Failure(ServerFailure('Server error')),
        );
        return ProductsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ProductsLoadRequested()),
      expect: () => [
        const ProductsLoading(),
        const ProductsError(message: 'Server error'),
      ],
    );

    blocTest<ProductsBloc, ProductsState>(
      'emits [Loading, Error] when ProductCreateRequested fails',
      build: () {
        when(
          () => mockRepository.createProduct(
            name: any(named: 'name'),
            type: any(named: 'type'),
            currency: any(named: 'currency'),
            defaultPrice: any(named: 'defaultPrice'),
            tags: any(named: 'tags'),
          ),
        ).thenAnswer(
          (_) async => const Failure(ServerFailure('Create failed')),
        );
        return ProductsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(
        const ProductCreateRequested(
          name: 'New',
          type: 'hardware',
          currency: 'USD',
        ),
      ),
      expect: () => [
        const ProductsLoading(),
        const ProductsError(message: 'Create failed'),
      ],
    );

    blocTest<ProductsBloc, ProductsState>(
      'emits [Loading, Loaded] when ProductCreateRequested succeeds '
      'and triggers reload',
      build: () {
        when(
          () => mockRepository.createProduct(
            name: any(named: 'name'),
            type: any(named: 'type'),
            currency: any(named: 'currency'),
            defaultPrice: any(named: 'defaultPrice'),
            tags: any(named: 'tags'),
          ),
        ).thenAnswer((_) async => Success(tProduct));
        when(() => mockRepository.getProducts())
            .thenAnswer((_) async => Success([tProduct]));
        return ProductsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(
        const ProductCreateRequested(
          name: 'Widget Pro',
          type: 'hardware',
          currency: 'USD',
          defaultPrice: 99.99,
        ),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const ProductsLoading(),
        ProductsLoaded(products: [tProduct]),
      ],
    );
  });
}
