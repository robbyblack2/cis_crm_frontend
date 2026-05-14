import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class AppFailure extends Equatable {
  const AppFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

final class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message = 'Unauthorized.']);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {this.fieldErrors});

  final Map<String, String>? fieldErrors;

  @override
  List<Object?> get props => [message, fieldErrors];
}

final class CacheFailure extends AppFailure {
  const CacheFailure([super.message = 'Cache error.']);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
