import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/products/domain/entities/subscription.dart';
import 'package:cis_crm/features/products/domain/repositories/subscription_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'subscriptions_event.dart';
part 'subscriptions_state.dart';

class SubscriptionsBloc extends Bloc<SubscriptionsEvent, SubscriptionsState> {
  SubscriptionsBloc({required SubscriptionRepository repository})
      : _repository = repository,
        super(const SubscriptionsInitial()) {
    on<SubscriptionsLoadRequested>(
      _onLoadRequested,
      transformer: restartable(),
    );
    on<SubscriptionCreateRequested>(
      _onCreateRequested,
      transformer: droppable(),
    );
  }

  final SubscriptionRepository _repository;

  Future<void> _onLoadRequested(
    SubscriptionsLoadRequested event,
    Emitter<SubscriptionsState> emit,
  ) async {
    emit(const SubscriptionsLoading());
    final result = await _repository.getSubscriptions();
    switch (result) {
      case Success(data: final subscriptions):
        emit(SubscriptionsLoaded(subscriptions: subscriptions));
      case Failure(error: final failure):
        emit(SubscriptionsError(message: failure.message));
    }
  }

  Future<void> _onCreateRequested(
    SubscriptionCreateRequested event,
    Emitter<SubscriptionsState> emit,
  ) async {
    emit(const SubscriptionsLoading());
    final result = await _repository.createSubscription(
      companyId: event.companyId,
      systemId: event.systemId,
      productType: event.productType,
      tags: event.tags,
    );
    switch (result) {
      case Success():
        add(const SubscriptionsLoadRequested());
      case Failure(error: final failure):
        emit(SubscriptionsError(message: failure.message));
    }
  }
}
