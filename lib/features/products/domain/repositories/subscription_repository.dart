import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/products/domain/entities/line_item.dart';
import 'package:cis_crm/features/products/domain/entities/subscription.dart';

abstract interface class SubscriptionRepository {
  Future<Result<List<Subscription>, AppFailure>> getSubscriptions();

  Future<Result<Subscription, AppFailure>> getSubscription({
    required String id,
  });

  Future<Result<Subscription, AppFailure>> createSubscription({
    required String companyId,
    required String systemId,
    required String productType,
    List<String> tags,
  });

  Future<Result<Subscription, AppFailure>> updateSubscription({
    required String id,
    required Map<String, dynamic> fields,
  });

  Future<Result<void, AppFailure>> deleteSubscription({required String id});

  Future<Result<List<LineItem>, AppFailure>> getLineItems({
    required String subscriptionId,
  });

  Future<Result<LineItem, AppFailure>> addLineItem({
    required String subscriptionId,
    required String productId,
    required int quantity,
    required double unitPrice,
    String? serialNumber,
    DateTime? startDate,
    DateTime? endDate,
  });
}
