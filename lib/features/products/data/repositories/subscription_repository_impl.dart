import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/products/data/datasources/subscription_remote_datasource.dart';
import 'package:cis_crm/features/products/domain/entities/line_item.dart';
import 'package:cis_crm/features/products/domain/entities/subscription.dart';
import 'package:cis_crm/features/products/domain/repositories/subscription_repository.dart';

final class SubscriptionRepositoryImpl implements SubscriptionRepository {
  const SubscriptionRepositoryImpl({
    required SubscriptionRemoteDatasource datasource,
  }) : _datasource = datasource;

  final SubscriptionRemoteDatasource _datasource;

  @override
  Future<Result<List<Subscription>, AppFailure>> getSubscriptions() async {
    try {
      final subscriptions = await _datasource.getSubscriptions();
      return Success(subscriptions);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<Subscription, AppFailure>> getSubscription({
    required String id,
  }) async {
    try {
      final subscription = await _datasource.getSubscription(id);
      return Success(subscription);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<Subscription, AppFailure>> createSubscription({
    required String companyId,
    required String systemId,
    required String productType,
    List<String> tags = const [],
  }) async {
    try {
      final subscription = await _datasource.createSubscription({
        'company_id': companyId,
        'system_id': systemId,
        'product_type': productType,
        'tags': tags,
      });
      return Success(subscription);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<Subscription, AppFailure>> updateSubscription({
    required String id,
    required Map<String, dynamic> fields,
  }) async {
    try {
      final subscription = await _datasource.updateSubscription(id, fields);
      return Success(subscription);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<void, AppFailure>> deleteSubscription({
    required String id,
  }) async {
    try {
      await _datasource.deleteSubscription(id);
      return const Success(null);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<List<LineItem>, AppFailure>> getLineItems({
    required String subscriptionId,
  }) async {
    try {
      final items = await _datasource.getLineItems(subscriptionId);
      return Success(items);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<LineItem, AppFailure>> addLineItem({
    required String subscriptionId,
    required String productId,
    required int quantity,
    required double unitPrice,
    String? serialNumber,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final item = await _datasource.addLineItem(subscriptionId, {
        'product_id': productId,
        'quantity': quantity,
        'unit_price': unitPrice,
        if (serialNumber != null) 'serial_number': serialNumber,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      });
      return Success(item);
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }
}
