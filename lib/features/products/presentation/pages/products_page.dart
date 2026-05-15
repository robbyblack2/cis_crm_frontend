import 'package:cis_crm/features/products/presentation/bloc/products_bloc.dart';
import 'package:cis_crm/features/products/presentation/widgets/product_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) {
          return switch (state) {
            ProductsInitial() =>
              const Center(child: Text('No products loaded.')),
            ProductsLoading() =>
              const Center(child: CircularProgressIndicator()),
            ProductsLoaded(:final products) => ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) =>
                    ProductTile(product: products[index]),
              ),
            ProductsError(:final message) =>
              Center(child: Text('Error: $message')),
          };
        },
      ),
    );
  }
}
