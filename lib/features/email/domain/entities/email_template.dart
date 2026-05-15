import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class EmailTemplate extends Equatable {
  const EmailTemplate({
    required this.id,
    required this.name,
    required this.subject,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String subject;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, name, subject, body, createdAt, updatedAt];
}
