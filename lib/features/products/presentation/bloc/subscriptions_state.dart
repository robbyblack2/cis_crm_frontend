part of 'subscriptions_bloc.dart';

@immutable
sealed class SubscriptionsState extends Equatable {
  const SubscriptionsState();

  @override
  List<Object?> get props => [];
}

final class SubscriptionsInitial extends SubscriptionsState {
  const SubscriptionsInitial();
}

final class SubscriptionsLoading extends SubscriptionsState {
  const SubscriptionsLoading();
}

final class SubscriptionsLoaded extends SubscriptionsState {
  const SubscriptionsLoaded({required this.subscriptions});

  final List<Subscription> subscriptions;

  @override
  List<Object?> get props => [subscriptions];
}

final class SubscriptionsError extends SubscriptionsState {
  const SubscriptionsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
