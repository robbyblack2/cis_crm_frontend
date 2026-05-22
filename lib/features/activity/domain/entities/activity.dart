import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum ActivityType { task, call, meeting }

enum ActivityPriority { none, low, medium, high }

@immutable
class Activity extends Equatable {
  const Activity({
    required this.id,
    required this.activityType,
    required this.title,
    required this.statusId,
    required this.statusName,
    required this.statusPhase,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.priority,
    this.assigneeId,
    this.subtypeId,
    this.subtypeName,
    this.dueDate,
    this.dueTime,
    this.completedAt,
    this.createdBy,
    this.data = const {},
    this.links = const [],
    // Meeting-specific fields
    this.startTime,
    this.endTime,
    this.attendees,
    this.meetingUrl,
    this.conferenceProvider,
    this.calendarProvider,
    this.calendarEventId,
    this.version = 1,
  });

  final String id;
  final ActivityType activityType;
  final String title;
  final String statusId;
  final String statusName;
  final String statusPhase; // "open" or "closed"
  final String? description;
  final ActivityPriority? priority;
  final String? assigneeId;
  final String? subtypeId;
  final String? subtypeName;
  final String? dueDate;
  final String? dueTime;
  final DateTime? completedAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> data;
  final List<ActivityLink> links;
  final int version;

  // Meeting-specific fields
  final DateTime? startTime;
  final DateTime? endTime;
  final List<Map<String, dynamic>>? attendees;
  final String? meetingUrl;
  final String? conferenceProvider;
  final String? calendarProvider;
  final String? calendarEventId;

  bool get isCompleted => statusPhase == 'closed';
  bool get isMeeting => activityType == ActivityType.meeting;
  bool get isTask => activityType == ActivityType.task;
  bool get isCall => activityType == ActivityType.call;

  @override
  List<Object?> get props => [
        id,
        activityType,
        title,
        statusId,
        statusName,
        statusPhase,
        description,
        priority,
        assigneeId,
        subtypeId,
        subtypeName,
        dueDate,
        dueTime,
        completedAt,
        createdBy,
        createdAt,
        updatedAt,
        data,
        links,
        startTime,
        endTime,
        attendees,
        meetingUrl,
        conferenceProvider,
        calendarProvider,
        calendarEventId,
        version,
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
