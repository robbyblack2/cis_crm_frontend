import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/features/settings/domain/entities/google_connection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class GoogleIntegrationState extends Equatable {
  const GoogleIntegrationState();

  @override
  List<Object?> get props => [];
}

final class GoogleIntegrationInitial extends GoogleIntegrationState {
  const GoogleIntegrationInitial();
}

final class GoogleIntegrationLoading extends GoogleIntegrationState {
  const GoogleIntegrationLoading();
}

final class GoogleIntegrationLoaded extends GoogleIntegrationState {
  const GoogleIntegrationLoaded(this.connection);

  final GoogleConnection connection;

  @override
  List<Object?> get props => [connection];
}

final class GoogleIntegrationError extends GoogleIntegrationState {
  const GoogleIntegrationError(this.failure);

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}
