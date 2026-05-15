import 'package:cis_crm/features/products/domain/entities/line_item.dart';
import 'package:cis_crm/features/products/domain/entities/subscription.dart';
import 'package:cis_crm/features/products/domain/entities/subscription_status.dart';
import 'package:cis_crm/features/products/presentation/widgets/line_item_tile.dart';
import 'package:flutter/material.dart';

class SubscriptionDetailPage extends StatelessWidget {
  const SubscriptionDetailPage({
    required this.subscription,
    this.lineItems = const [],
    super.key,
  });

  final Subscription subscription;
  final List<LineItem> lineItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription ${subscription.systemId}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Details card ────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'System ID',
                      value: subscription.systemId,
                    ),
                    const Divider(),
                    _DetailRow(
                      label: 'Company',
                      value: subscription.companyId,
                    ),
                    const Divider(),
                    _DetailRow(
                      label: 'Product Type',
                      value: subscription.productType,
                    ),
                    const Divider(),
                    _StatusRow(status: subscription.status),
                    if (subscription.tags.isNotEmpty) ...[
                      const Divider(),
                      Text('Tags', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: subscription.tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Line Items card ─────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Line Items',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (lineItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No line items',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      ...lineItems.map(
                        (item) => LineItemTile(lineItem: item),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = _labelAndColor(theme.colorScheme, status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'Status',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Chip(
            label: Text(label, style: TextStyle(color: color, fontSize: 12)),
            side: BorderSide(color: color),
            backgroundColor: color.withValues(alpha: 0.1),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  static (String, Color) _labelAndColor(
    ColorScheme cs,
    SubscriptionStatus status,
  ) {
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
