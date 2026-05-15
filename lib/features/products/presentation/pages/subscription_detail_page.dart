import 'package:cis_crm/features/products/domain/entities/subscription.dart';
import 'package:flutter/material.dart';

class SubscriptionDetailPage extends StatelessWidget {
  const SubscriptionDetailPage({required this.subscription, super.key});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subscription.id)),
      body: const Placeholder(),
    );
  }
}
