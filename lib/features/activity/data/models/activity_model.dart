import 'package:cis_crm/features/activity/domain/entities/activity.dart';

const _typeMap = {
  'task': ActivityType.task,
  'call': ActivityType.call,
  'meeting': ActivityType.meeting,
  'email': ActivityType.email,
};

const _typeToString = {
  ActivityType.task: 'task',
  ActivityType.call: 'call',
  ActivityType.meeting: 'meeting',
  ActivityType.email: 'email',
};

const _priorityMap = {
  'low': ActivityPriority.low,
  'medium': ActivityPriority.medium,
  'high': ActivityPriority.high,
};

const _priorityToString = {
  ActivityPriority.low: 'low',
  ActivityPriority.medium: 'medium',
  ActivityPriority.high: 'high',
};

class ActivityModel extends Activity {
  const ActivityModel({
    required super.id,
    required super.activityType,
    required super.title,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.description,
    super.priority,
    super.assigneeId,
    super.dueDate,
    super.dueTime,
    super.completedAt,
    super.createdBy,
    super.data,
    super.links,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    final linksRaw = json['links'] as List<dynamic>? ?? [];
    return ActivityModel(
      id: json['id'] as String,
      activityType:
          _typeMap[json['activity_type'] as String?] ?? ActivityType.task,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      description: json['description'] as String?,
      priority: _priorityMap[json['priority'] as String?],
      assigneeId: json['assignee_id'] as String?,
      dueDate: json['due_date'] as String?,
      dueTime: json['due_time'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      data: json['data'] as Map<String, dynamic>? ?? const {},
      links: linksRaw
          .whereType<Map<String, dynamic>>()
          .map(
            (l) => ActivityLink(
              entityType: l['entity_type'] as String? ?? '',
              entityId: l['entity_id'] as String? ?? '',
              linkId: l['id'] as String?,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'activity_type': _typeToString[activityType],
        'title': title,
        'status': status,
        if (description != null) 'description': description,
        if (priority != null) 'priority': _priorityToString[priority],
        if (assigneeId != null) 'assignee_id': assigneeId,
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
      };
}
