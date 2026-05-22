import 'package:cis_crm/features/activity/domain/entities/timeline_entry.dart';

class TimelineEntryModel extends TimelineEntry {
  const TimelineEntryModel({
    required super.id,
    required super.entityType,
    required super.entityId,
    required super.eventType,
    required super.actorType,
    required super.actorId,
    required super.summary,
    required super.createdAt,
  });

  factory TimelineEntryModel.fromJson(Map<String, dynamic> json) {
    return TimelineEntryModel(
      id: json['id']?.toString() ?? '',
      entityType: json['entity_type'] as String? ?? '',
      entityId: json['entity_id']?.toString() ?? '',
      eventType: json['event_type'] as String? ?? '',
      actorType: json['actor_type'] as String? ?? '',
      actorId: json['actor_id']?.toString() ?? '',
      summary: json['summary'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'event_type': eventType,
        'actor_type': actorType,
        'actor_id': actorId,
        'summary': summary,
        'created_at': createdAt.toIso8601String(),
      };
}
