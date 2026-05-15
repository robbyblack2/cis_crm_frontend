import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class Report extends Equatable {
  const Report({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
