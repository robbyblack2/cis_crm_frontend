import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Domain entity for the `example` feature.
///
/// Pure Dart — no JSON, no Flutter, no Dio. Used by the bloc directly.
/// The `data/` layer's `ExampleModel` extends this and adds JSON support.
@immutable
class ExampleEntity extends Equatable {
  const ExampleEntity({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  ExampleEntity copyWith({
    String? id,
    String? name,
    Object? description = _sentinel,
  }) {
    return ExampleEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: identical(description, _sentinel)
          ? this.description
          : description as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, description];
}

const _sentinel = Object();
