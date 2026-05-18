import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/widgets/state/empty_state.dart';
import 'package:cis_crm/core/widgets/state/page_error.dart';
import 'package:cis_crm/core/widgets/state/page_loading.dart';
import 'package:cis_crm/features/products/presentation/bloc/products_bloc.dart';
import 'package:cis_crm/features/products/presentation/bloc/subscriptions_bloc.dart';
import 'package:cis_crm/features/products/presentation/pages/product_detail_page.dart';
import 'package:cis_crm/features/products/presentation/pages/subscription_detail_page.dart';
import 'package:cis_crm/features/products/presentation/widgets/product_tile.dart';
import 'package:cis_crm/features/products/presentation/widgets/subscription_tile.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<ProductsBloc>()..add(const ProductsLoadRequested()),
        ),
        BlocProvider(
          create: (_) => getIt<SubscriptionsBloc>()
            ..add(const SubscriptionsLoadRequested()),
        ),
      ],
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatelessWidget {
  const _ProductsView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.productsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.catalogTab),
              Tab(text: AppLocalizations.of(context)!.subscriptionsTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CatalogTab(),
            _SubscriptionsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO(nav): Navigate to add product form.
          },
          tooltip: AppLocalizations.of(context)!.addProduct,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

// ── Catalog Tab ─────────────────────────────────────────────────────────────

class _CatalogTab extends StatelessWidget {
  const _CatalogTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, state) {
        return switch (state) {
          ProductsInitial() ||
          ProductsLoading() =>
            PageLoading(label: AppLocalizations.of(context)!.productsLoading),
          ProductsError(:final message) => PageError(
              title: AppLocalizations.of(context)!.failedToLoadProducts,
              message: message,
              onRetry: () => context
                  .read<ProductsBloc>()
                  .add(const ProductsLoadRequested()),
            ),
          ProductsLoaded(:final products) => products.isEmpty
              ? EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: AppLocalizations.of(context)!.productsEmpty,
                  message: AppLocalizations.of(context)!.productsEmptyMessage,
                )
              : ListView.separated(
                  itemCount: products.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductTile(
                      product: product,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProductDetailPage(product: product),
                        ),
                      ),
                    );
                  },
                ),
        };
      },
    );
  }
}

// ── Subscriptions Tab ───────────────────────────────────────────────────────

class _SubscriptionsTab extends StatelessWidget {
  const _SubscriptionsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionsBloc, SubscriptionsState>(
      builder: (context, state) {
        return switch (state) {
          SubscriptionsInitial() ||
          SubscriptionsLoading() =>
            PageLoading(label: AppLocalizations.of(context)!.subscriptionsLoading),
          SubscriptionsError(:final message) => PageError(
              title: AppLocalizations.of(context)!.failedToLoadSubscriptions,
              message: message,
              onRetry: () => context
                  .read<SubscriptionsBloc>()
                  .add(const SubscriptionsLoadRequested()),
            ),
          SubscriptionsLoaded(:final subscriptions) => subscriptions.isEmpty
              ? EmptyState(
                  icon: Icons.subscriptions_outlined,
                  title: AppLocalizations.of(context)!.subscriptionsEmpty,
                  message: AppLocalizations.of(context)!.subscriptionsEmptyMessage,
                )
              : ListView.separated(
                  itemCount: subscriptions.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sub = subscriptions[index];
                    return SubscriptionTile(
                      subscription: sub,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              SubscriptionDetailPage(subscription: sub),
                        ),
                      ),
                    );
                  },
                ),
        };
      },
    );
  }
}
