import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum ActivityType { task, call, meeting, email }

enum ActivityPriority { low, medium, high }

@immutable
class Activity extends Equatable {
  const Activity({
    required this.id,
    required this.activityType,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.priority,
    this.assigneeId,
    this.dueDate,
    this.dueTime,
    this.completedAt,
    this.createdBy,
    this.data = const {},
    this.links = const [],
  });

  final String id;
  final ActivityType activityType;
  final String title;
  final String status;
  final String? description;
  final ActivityPriority? priority;
  final String? assigneeId;
  final String? dueDate;
  final String? dueTime;
  final DateTime? completedAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> data;
  final List<ActivityLink> links;

  @override
  List<Object?> get props => [
        id,
        activityType,
        title,
        status,
        description,
        priority,
        assigneeId,
        dueDate,
        dueTime,
        completedAt,
        createdBy,
        createdAt,
        updatedAt,
        data,
        links,
      ];
}

@immutable
class ActivityLink extends Equatable {
  const ActivityLink({
    required this.entityType,
    required this.entityId,
    this.linkId,
  });

  final String entityType;
  final String entityId;
  final String? linkId;

  @override
  List<Object?> get props => [entityType, entityId, linkId];
}
