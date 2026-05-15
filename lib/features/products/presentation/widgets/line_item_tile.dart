import 'package:cis_crm/features/products/domain/entities/line_item.dart';
import 'package:flutter/material.dart';

class LineItemTile extends StatelessWidget {
  const LineItemTile({
    required this.lineItem,
    super.key,
  });

  final LineItem lineItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = lineItem.quantity * lineItem.unitPrice;
    final sn = lineItem.serialNumber;
    final snSuffix = sn != null ? ' \u2022 S/N: $sn' : '';
    return ListTile(
      leading: const Icon(Icons.receipt_long_outlined),
      title: Text(lineItem.productId),
      subtitle: Text(
        '${lineItem.quantity} \u00d7 '
        '\$${lineItem.unitPrice.toStringAsFixed(2)}'
        ' = \$${total.toStringAsFixed(2)}'
        '$snSuffix',
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      titleTextStyle: theme.textTheme.bodyMedium,
      subtitleTextStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
