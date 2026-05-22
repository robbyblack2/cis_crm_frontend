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

/// Extracts a meeting URL from the data JSONB field.
/// Google Calendar sync may store the link under various keys.
String? _extractMeetingUrl(Map<String, dynamic>? data) {
  if (data == null) return null;
  // Try common keys where a meeting URL might be stored
  for (final key in [
    'meeting_url',
    'meetingUrl',
    'hangout_link',
    'hangoutLink',
    'html_link',
    'htmlLink',
    'join_url',
    'joinUrl',
    'conference_url',
    'conferenceUrl',
  ]) {
    final value = data[key];
    if (value is String && value.isNotEmpty) return value;
  }
  // Check nested conference_data for entry points
  final confData = data['conference_data'] ?? data['conferenceData'];
  if (confData is Map<String, dynamic>) {
    final entryPoints = confData['entry_points'] ?? confData['entryPoints'];
    if (entryPoints is List && entryPoints.isNotEmpty) {
      final first = entryPoints.first;
      if (first is Map<String, dynamic>) {
        final uri = first['uri'] as String?;
        if (uri != null && uri.isNotEmpty) return uri;
      }
    }
  }
  return null;
}

/// Infers conference provider from a meeting URL.
String? _extractConferenceProvider(Map<String, dynamic>? data, String? url) {
  if (data != null) {
    final provider = data['conference_provider'] ?? data['conferenceProvider'];
    if (provider is String && provider.isNotEmpty) return provider;
  }
  if (url == null) return null;
  if (url.contains('meet.google.com')) return 'google_meet';
  if (url.contains('zoom.us') || url.contains('zoom.com')) return 'zoom';
  if (url.contains('teams.microsoft.com')) return 'teams';
  return 'other';
}

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
      meetingUrl: json['meeting_url'] as String? ??
          _extractMeetingUrl(json['data'] as Map<String, dynamic>?),
      conferenceProvider: json['conference_provider'] as String? ??
          _extractConferenceProvider(
              json['data'] as Map<String, dynamic>?,
              json['meeting_url'] as String? ??
                  _extractMeetingUrl(json['data'] as Map<String, dynamic>?)),
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
        if (data.isNotEmpty) 'data': Map<String, dynamic>.from(data)
          ..remove('create_meet_link'),
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
        // create_meet_link and create_google_event are top-level API flags.
        // create_meet_link is stored in data for transport and extracted
        // here. create_google_event is always true when creating a Meet.
        if (data.containsKey('create_meet_link'))
          'create_meet_link': data['create_meet_link'],
        if (data.containsKey('create_meet_link'))
          'create_google_event': true,
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
