import 'package:cis_crm/features/products/domain/entities/line_item.dart';
import 'package:flutter/material.dart';

class LineItemTile extends StatelessWidget {
  const LineItemTile({required this.lineItem, super.key});

  final LineItem lineItem;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Product: ${lineItem.productId}'),
      subtitle: Text('Qty: ${lineItem.quantity}'),
      trailing: Text('\$${lineItem.unitPrice.toStringAsFixed(2)}'),
    );
  }
}
