import 'package:cis_crm/features/products/domain/entities/subscription_status.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class Subscription extends Equatable {
  const Subscription({
    required this.id,
    required this.companyId,
    required this.systemId,
    required this.productType,
    required this.status,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String companyId;
  final String systemId;
  final String productType;
  final SubscriptionStatus status;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        companyId,
        systemId,
        productType,
        status,
        tags,
        createdAt,
        updatedAt,
      ];
}
