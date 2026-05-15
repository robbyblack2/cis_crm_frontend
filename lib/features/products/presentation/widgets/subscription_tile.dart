import 'package:cis_crm/features/products/domain/entities/subscription.dart';
import 'package:flutter/material.dart';

class SubscriptionTile extends StatelessWidget {
  const SubscriptionTile({required this.subscription, super.key});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(subscription.productType),
      subtitle: Text(subscription.status.name),
      trailing: Text(subscription.companyId),
    );
  }
}
