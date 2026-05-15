import 'package:cis_crm/features/products/presentation/bloc/subscriptions_bloc.dart';
import 'package:cis_crm/features/products/presentation/widgets/subscription_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      body: BlocBuilder<SubscriptionsBloc, SubscriptionsState>(
        builder: (context, state) {
          return switch (state) {
            SubscriptionsInitial() =>
              const Center(child: Text('No subscriptions loaded.')),
            SubscriptionsLoading() =>
              const Center(child: CircularProgressIndicator()),
            SubscriptionsLoaded(:final subscriptions) => ListView.builder(
                itemCount: subscriptions.length,
                itemBuilder: (context, index) =>
                    SubscriptionTile(subscription: subscriptions[index]),
              ),
            SubscriptionsError(:final message) =>
              Center(child: Text('Error: $message')),
          };
        },
      ),
    );
  }
}
