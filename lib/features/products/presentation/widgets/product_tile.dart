import 'package:cis_crm/features/products/domain/entities/product.dart';
import 'package:flutter/material.dart';

class ProductTile extends StatelessWidget {
  const ProductTile({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(product.name),
      subtitle: Text(product.type.name),
      trailing: product.defaultPrice != null
          ? Text('${product.currency} ${product.defaultPrice}')
          : null,
    );
  }
}
