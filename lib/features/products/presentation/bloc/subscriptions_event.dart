part of 'subscriptions_bloc.dart';

@immutable
sealed class SubscriptionsEvent extends Equatable {
  const SubscriptionsEvent();

  @override
  List<Object?> get props => [];
}

final class SubscriptionsLoadRequested extends SubscriptionsEvent {
  const SubscriptionsLoadRequested();
}

final class SubscriptionCreateRequested extends SubscriptionsEvent {
  const SubscriptionCreateRequested({
    required this.companyId,
    required this.systemId,
    required this.productType,
    this.tags = const [],
  });

  final String companyId;
  final String systemId;
  final String productType;
  final List<String> tags;

  @override
  List<Object?> get props => [companyId, systemId, productType, tags];
}
