import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/products/domain/entities/product.dart';

abstract interface class ProductRepository {
  Future<Result<List<Product>, AppFailure>> getProducts();

  Future<Result<Product, AppFailure>> createProduct({
    required String name,
    required String type,
    required String currency,
    double? defaultPrice,
    List<String> tags,
  });

  Future<Result<Product, AppFailure>> updateProduct({
    required String id,
    required Map<String, dynamic> fields,
  });

  Future<Result<void, AppFailure>> deleteProduct({required String id});
}
