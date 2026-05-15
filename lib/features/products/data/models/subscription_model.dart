import 'package:cis_crm/features/products/domain/entities/subscription.dart';
import 'package:cis_crm/features/products/domain/entities/subscription_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SubscriptionModel extends Subscription {
  const SubscriptionModel({
    required super.id,
    required super.companyId,
    required super.systemId,
    required super.productType,
    required super.status,
    required super.tags,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionModelToJson(this);
}
