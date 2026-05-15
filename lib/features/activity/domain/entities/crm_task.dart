import 'package:cis_crm/features/activity/domain/entities/task_priority.dart';
import 'package:cis_crm/features/activity/domain/entities/task_status.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class CrmTask extends Equatable {
  const CrmTask({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.parentType,
    required this.parentId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.assigneeId,
    this.dueDate,
    this.completedAt,
  });

  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? assigneeId;
  final DateTime? dueDate;
  final String parentType;
  final String parentId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        priority,
        assigneeId,
        dueDate,
        parentType,
        parentId,
        createdBy,
        createdAt,
        updatedAt,
        completedAt,
      ];
}
