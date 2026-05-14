import 'package:flutter/foundation.dart';

@immutable
sealed class Result<T, F> {
  const Result();

  T? get dataOrNull => switch (this) {
        Success<T, F>(:final data) => data,
        Failure<T, F>() => null,
      };

  F? get failureOrNull => switch (this) {
        Success<T, F>() => null,
        Failure<T, F>(:final error) => error,
      };

  bool get isSuccess => this is Success<T, F>;
  bool get isFailure => this is Failure<T, F>;
}

@immutable
final class Success<T, F> extends Result<T, F> {
  const Success(this.data);

  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success<T, F> && other.data == data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success<$T, $F>($data)';
}

@immutable
final class Failure<T, F> extends Result<T, F> {
  const Failure(this.error);

  final F error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Failure<T, F> && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure<$T, $F>($error)';
}
