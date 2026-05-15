import 'package:cis_crm/features/products/domain/entities/subscription.dart';
import 'package:cis_crm/features/products/domain/entities/subscription_status.dart';
import 'package:flutter/material.dart';

class SubscriptionTile extends StatelessWidget {
  const SubscriptionTile({
    required this.subscription,
    this.onTap,
    super.key,
  });

  final Subscription subscription;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.subscriptions_outlined)),
      title: Text(subscription.systemId),
      subtitle: Text(
        'Company: ${subscription.companyId}'
        ' \u2022 ${subscription.productType}',
      ),
      trailing: _StatusChip(status: subscription.status),
      onTap: onTap,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _labelAndColor(context, status);
    return Chip(
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
      side: BorderSide(color: color),
      backgroundColor: color.withValues(alpha: 0.1),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  static (String, Color) _labelAndColor(
    BuildContext context,
    SubscriptionStatus status,
  ) {
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      SubscriptionStatus.active => ('Active', cs.primary),
      SubscriptionStatus.trialing => ('Trialing', cs.tertiary),
      SubscriptionStatus.pastDue => ('Past Due', cs.error),
      SubscriptionStatus.paused => ('Paused', cs.outline),
      SubscriptionStatus.cancelled => ('Cancelled', cs.onSurfaceVariant),
      SubscriptionStatus.expired => ('Expired', cs.error),
    };
  }
}
