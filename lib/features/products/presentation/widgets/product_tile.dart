import 'package:cis_crm/features/products/domain/entities/product.dart';
import 'package:cis_crm/features/products/domain/entities/product_type.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class ProductTile extends StatelessWidget {
  const ProductTile({
    required this.product,
    this.onTap,
    this.onDeleted,
    super.key,
  });

  final Product product;
  final VoidCallback? onTap;
  final ValueChanged<String>? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          _iconForType(product.type),
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(product.name),
      subtitle: Text(
        '${product.currency} '
        '${product.defaultPrice?.toStringAsFixed(2) ?? 'N/A'}',
      ),
      trailing: _ActiveBadge(isActive: product.isActive),
      onTap: onTap,
    );

    if (onDeleted == null) return tile;

    return Dismissible(
      key: ValueKey(product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      onDismissed: (_) => onDeleted!(product.id),
      child: tile,
    );
  }

  static IconData _iconForType(ProductType type) {
    return switch (type) {
      ProductType.hardware => Icons.memory,
      ProductType.subscription => Icons.autorenew,
      ProductType.service => Icons.build_outlined,
    };
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive
            ? AppLocalizations.of(context)!.productActive
            : AppLocalizations.of(context)!.productInactive,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isActive
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
