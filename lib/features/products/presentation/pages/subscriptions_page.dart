import 'package:cis_crm/features/products/presentation/bloc/subscriptions_bloc.dart';
import 'package:cis_crm/features/products/presentation/widgets/subscription_tile.dart';
import 'package:cis_crm/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.subscriptionsPageTitle)),
      body: BlocBuilder<SubscriptionsBloc, SubscriptionsState>(
        builder: (context, state) {
          return switch (state) {
            SubscriptionsInitial() =>
              Center(child: Text(AppLocalizations.of(context)!.noSubscriptionsLoaded)),
            SubscriptionsLoading() =>
              const Center(child: CircularProgressIndicator()),
            SubscriptionsLoaded(:final subscriptions) => ListView.builder(
                itemCount: subscriptions.length,
                itemBuilder: (context, index) =>
                    SubscriptionTile(subscription: subscriptions[index]),
              ),
            SubscriptionsError(:final message) =>
              Center(child: Text(AppLocalizations.of(context)!.errorPrefix(message))),
          };
        },
      ),
    );
  }
}
