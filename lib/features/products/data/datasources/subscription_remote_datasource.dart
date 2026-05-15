import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/products/data/models/line_item_model.dart';
import 'package:cis_crm/features/products/data/models/subscription_model.dart';
import 'package:dio/dio.dart';

abstract interface class SubscriptionRemoteDatasource {
  Future<List<SubscriptionModel>> getSubscriptions();
  Future<SubscriptionModel> getSubscription(String id);
  Future<SubscriptionModel> createSubscription(Map<String, dynamic> body);
  Future<SubscriptionModel> updateSubscription(
    String id,
    Map<String, dynamic> body,
  );
  Future<void> deleteSubscription(String id);
  Future<List<LineItemModel>> getLineItems(String subscriptionId);
  Future<LineItemModel> addLineItem(
    String subscriptionId,
    Map<String, dynamic> body,
  );
}

final class SubscriptionRemoteDatasourceImpl
    implements SubscriptionRemoteDatasource {
  const SubscriptionRemoteDatasourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<SubscriptionModel>> getSubscriptions() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/subscriptions');
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(SubscriptionModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to load subscriptions',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<SubscriptionModel> getSubscription(String id) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/subscriptions/$id');
      return SubscriptionModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to load subscription',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<SubscriptionModel> createSubscription(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/subscriptions',
        data: body,
      );
      return SubscriptionModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to create subscription',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<SubscriptionModel> updateSubscription(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/subscriptions/$id',
        data: body,
      );
      return SubscriptionModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update subscription',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteSubscription(String id) async {
    try {
      await _dio.delete<void>('/api/subscriptions/$id');
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete subscription',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<LineItemModel>> getLineItems(String subscriptionId) async {
    try {
      final response = await _dio
          .get<List<dynamic>>('/api/subscriptions/$subscriptionId/line-items');
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(LineItemModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to load line items',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<LineItemModel> addLineItem(
    String subscriptionId,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/subscriptions/$subscriptionId/line-items',
        data: body,
      );
      return LineItemModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to add line item',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
