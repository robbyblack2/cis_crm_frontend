import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class AutomationRule extends Equatable {
  const AutomationRule({
    required this.id,
    required this.name,
    required this.isActive,
    required this.triggerType,
    required this.priority,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final String triggerType;
  final int priority;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        isActive,
        triggerType,
        priority,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
