import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/products/domain/entities/product.dart';
import 'package:cis_crm/features/products/domain/entities/product_type.dart';
import 'package:cis_crm/features/products/domain/repositories/product_repository.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            tooltip: AppLocalizations.of(context)!.delete,
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  label: AppLocalizations.of(context)!.productNameLabel,
                  value: product.name,
                ),
                const Divider(),
                _DetailRow(
                  label: AppLocalizations.of(context)!.productType,
                  value: product.type.name,
                  icon: _iconForType(product.type),
                ),
                const Divider(),
                _DetailRow(
                  label: AppLocalizations.of(context)!.productDefaultPrice,
                  value: '${product.currency} '
                      '${product.defaultPrice?.toStringAsFixed(2) ?? 'N/A'}',
                ),
                const Divider(),
                _DetailRow(
                  label: AppLocalizations.of(context)!.productStatus,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: product.isActive
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.isActive ? AppLocalizations.of(context)!.productActive : AppLocalizations.of(context)!.productInactive,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: product.isActive
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                if (product.tags.isNotEmpty) ...[
                  const Divider(),
                  Text(AppLocalizations.of(context)!.contactTags, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: product.tags
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
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteRecord),
        content: Text(l10n.deleteRecordConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true || !context.mounted) return;
      final result =
          await getIt<ProductRepository>().deleteProduct(id: product.id);
      if (!context.mounted) return;
      switch (result) {
        case Success():
          Navigator.of(context).pop();
        case Failure(:final error):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: ${error.message}')),
          );
      }
    });
  }

  static IconData _iconForType(ProductType type) {
    return switch (type) {
      ProductType.hardware => Icons.memory,
      ProductType.subscription => Icons.autorenew,
      ProductType.service => Icons.build_outlined,
    };
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    this.value,
    this.icon,
    this.child,
  });

  final String label;
  final String? value;
  final IconData? icon;
  final Widget? child;

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
          if (child != null)
            child!
          else ...[
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                value ?? '',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
