import 'package:cis_crm/features/products/domain/entities/line_item.dart';
import 'package:cis_crm/features/products/domain/entities/subscription.dart';
import 'package:cis_crm/features/products/domain/entities/subscription_status.dart';
import 'package:cis_crm/features/products/presentation/widgets/line_item_tile.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
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
        title: Text(AppLocalizations.of(context)!.subscriptionTitle(subscription.systemId)),
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
                      AppLocalizations.of(context)!.details,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: AppLocalizations.of(context)!.subscriptionSystemId,
                      value: subscription.systemId,
                    ),
                    const Divider(),
                    _DetailRow(
                      label: AppLocalizations.of(context)!.subscriptionCompany,
                      value: subscription.companyId,
                    ),
                    const Divider(),
                    _DetailRow(
                      label: AppLocalizations.of(context)!.subscriptionProductType,
                      value: subscription.productType,
                    ),
                    const Divider(),
                    _StatusRow(status: subscription.status),
                    if (subscription.tags.isNotEmpty) ...[
                      const Divider(),
                      Text(AppLocalizations.of(context)!.contactTags, style: theme.textTheme.labelMedium),
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
                      AppLocalizations.of(context)!.lineItems,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (lineItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.noLineItems,
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
    final (label, color) = _labelAndColor(context, theme.colorScheme, status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              AppLocalizations.of(context)!.status,
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
    BuildContext context,
    ColorScheme cs,
    SubscriptionStatus status,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return switch (status) {
      SubscriptionStatus.active => (l10n.statusActive, cs.primary),
      SubscriptionStatus.trialing => (l10n.statusTrialing, cs.tertiary),
      SubscriptionStatus.pastDue => (l10n.statusPastDue, cs.error),
      SubscriptionStatus.paused => (l10n.statusPaused, cs.outline),
      SubscriptionStatus.cancelled => (l10n.statusCancelled, cs.onSurfaceVariant),
      SubscriptionStatus.expired => (l10n.statusExpired, cs.error),
    };
  }
}
