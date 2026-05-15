import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/products/data/datasources/product_remote_datasource.dart';
import 'package:cis_crm/features/products/domain/entities/product.dart';
import 'package:cis_crm/features/products/domain/repositories/product_repository.dart';

final class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl({required ProductRemoteDatasource datasource})
      : _datasource = datasource;

  final ProductRemoteDatasource _datasource;

  @override
  Future<Result<List<Product>, AppFailure>> getProducts() async {
    try {
      final products = await _datasource.getProducts();
      return Success(products);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<Product, AppFailure>> createProduct({
    required String name,
    required String type,
    required String currency,
    double? defaultPrice,
    List<String> tags = const [],
  }) async {
    try {
      final product = await _datasource.createProduct({
        'name': name,
        'type': type,
        'currency': currency,
        if (defaultPrice != null) 'default_price': defaultPrice,
        'tags': tags,
      });
      return Success(product);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<Product, AppFailure>> updateProduct({
    required String id,
    required Map<String, dynamic> fields,
  }) async {
    try {
      final product = await _datasource.updateProduct(id, fields);
      return Success(product);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<void, AppFailure>> deleteProduct({required String id}) async {
    try {
      await _datasource.deleteProduct(id);
      return const Success(null);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }
}
