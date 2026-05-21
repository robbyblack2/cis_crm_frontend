import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class EmailTemplate extends Equatable {
  const EmailTemplate({
    required this.id,
    required this.name,
    required this.subjectTemplate,
    required this.bodyTemplate,
    required this.createdAt,
    required this.updatedAt,
    this.variables,
    this.createdBy,
  });

  final String id;
  final String name;
  final String subjectTemplate;
  final String bodyTemplate;
  final dynamic variables;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        name,
        subjectTemplate,
        bodyTemplate,
        variables,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
