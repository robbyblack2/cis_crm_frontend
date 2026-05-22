import 'package:cis_crm/features/activity/domain/entities/activity.dart';

const _typeMap = {
  'task': ActivityType.task,
  'call': ActivityType.call,
  'meeting': ActivityType.meeting,
};

const _typeToString = {
  ActivityType.task: 'task',
  ActivityType.call: 'call',
  ActivityType.meeting: 'meeting',
};

const _priorityMap = {
  'none': ActivityPriority.none,
  'low': ActivityPriority.low,
  'medium': ActivityPriority.medium,
  'high': ActivityPriority.high,
};

const _priorityToString = {
  ActivityPriority.none: 'none',
  ActivityPriority.low: 'low',
  ActivityPriority.medium: 'medium',
  ActivityPriority.high: 'high',
};

/// Safely converts a JSON value (int or String) to String?, returning null
/// when the value is actually null.
String? _toStringOrNull(Object? value) => value?.toString();

class ActivityModel extends Activity {
  const ActivityModel({
    required super.id,
    required super.activityType,
    required super.title,
    required super.statusId,
    required super.statusName,
    required super.statusPhase,
    required super.createdAt,
    required super.updatedAt,
    super.description,
    super.priority,
    super.assigneeId,
    super.subtypeId,
    super.subtypeName,
    super.dueDate,
    super.dueTime,
    super.completedAt,
    super.createdBy,
    super.data,
    super.links,
    super.startTime,
    super.endTime,
    super.attendees,
    super.meetingUrl,
    super.conferenceProvider,
    super.calendarProvider,
    super.calendarEventId,
    super.version,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    final linksRaw = json['links'] as List<dynamic>? ?? [];
    final attendeesRaw = json['attendees'] as List<dynamic>?;

    // Backend may return nested status/subtype objects or flat fields.
    final statusObj = json['status'] as Map<String, dynamic>?;
    final subtypeObj = json['subtype'] as Map<String, dynamic>?;

    return ActivityModel(
      id: json['id']?.toString() ?? '',
      activityType:
          _typeMap[json['activity_type'] as String?] ?? ActivityType.task,
      title: json['title'] as String? ?? '',
      statusId: json['status_id']?.toString() ?? '',
      statusName: json['status_name'] as String? ??
          statusObj?['name'] as String? ??
          '',
      statusPhase: json['status_phase'] as String? ??
          statusObj?['phase'] as String? ??
          'open',
      description: json['description'] as String?,
      priority: _priorityMap[json['priority'] as String?],
      assigneeId: _toStringOrNull(json['assignee_id']),
      subtypeId: _toStringOrNull(json['subtype_id']),
      subtypeName: json['subtype_name'] as String? ??
          subtypeObj?['name'] as String?,
      dueDate: json['due_date'] as String?,
      dueTime: json['due_time'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      createdBy: _toStringOrNull(json['created_by']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      data: json['data'] as Map<String, dynamic>? ?? const {},
      links: linksRaw
          .whereType<Map<String, dynamic>>()
          .map(
            (l) => ActivityLink(
              entityType: l['entity_type'] as String? ?? '',
              entityId: l['entity_id']?.toString() ?? '',
              linkId: l['id']?.toString(),
            ),
          )
          .toList(),
      version: json['version'] as int? ?? 1,
      // Meeting-specific fields
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'] as String)
          : null,
      attendees: attendeesRaw
          ?.whereType<Map<String, dynamic>>()
          .toList(),
      meetingUrl: json['meeting_url'] as String?,
      conferenceProvider: json['conference_provider'] as String?,
      calendarProvider: json['calendar_provider'] as String?,
      calendarEventId: json['calendar_event_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'activity_type': _typeToString[activityType],
        'title': title,
        if (statusId.isNotEmpty) 'status_id': statusId,
        if (description != null) 'description': description,
        if (priority != null) 'priority': _priorityToString[priority],
        if (assigneeId != null) 'assignee_id': assigneeId,
        if (subtypeId != null) 'subtype_id': subtypeId,
        if (dueDate != null) 'due_date': dueDate,
        if (dueTime != null) 'due_time': dueTime,
        if (data.isNotEmpty) 'data': data,
        if (links.isNotEmpty)
          'links': links
              .map((l) => {
                    'entity_type': l.entityType,
                    'entity_id': l.entityId,
                  })
              .toList(),
        // Meeting-specific
        if (startTime != null)
          'start_time': startTime!.toUtc().toIso8601String(),
        if (endTime != null)
          'end_time': endTime!.toUtc().toIso8601String(),
        if (attendees != null) 'attendees': attendees,
        if (meetingUrl != null) 'meeting_url': meetingUrl,
      };

  /// Build a create payload for POST /api/activities (meeting-specific).
  static Map<String, dynamic> createMeetingPayload({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? statusId,
    String? subtypeId,
    List<Map<String, dynamic>>? attendees,
    bool createMeetLink = true,
    bool createGoogleEvent = true,
    Map<String, dynamic>? data,
    List<Map<String, dynamic>>? links,
  }) =>
      {
        'activity_type': 'meeting',
        'title': title,
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        if (description != null) 'description': description,
        if (statusId != null) 'status_id': statusId,
        if (subtypeId != null) 'subtype_id': subtypeId,
        if (attendees != null) 'attendees': attendees,
        'create_meet_link': createMeetLink,
        'create_google_event': createGoogleEvent,
        if (data != null) 'data': data,
        if (links != null) 'links': links,
      };
}
