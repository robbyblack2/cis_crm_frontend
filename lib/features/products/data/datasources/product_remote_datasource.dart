import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/products/data/models/product_model.dart';
import 'package:dio/dio.dart';

abstract interface class ProductRemoteDatasource {
  Future<List<ProductModel>> getProducts();
  Future<ProductModel> createProduct(Map<String, dynamic> body);
  Future<ProductModel> updateProduct(String id, Map<String, dynamic> body);
  Future<void> deleteProduct(String id);
}

final class ProductRemoteDatasourceImpl implements ProductRemoteDatasource {
  const ProductRemoteDatasourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/products');
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to load products',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ProductModel> createProduct(Map<String, dynamic> body) async {
    try {
      final response =
          await _dio.post<Map<String, dynamic>>('/api/products', data: body);
      return ProductModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to create product',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ProductModel> updateProduct(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/products/$id',
        data: body,
      );
      return ProductModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update product',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _dio.delete<void>('/api/products/$id');
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete product',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
