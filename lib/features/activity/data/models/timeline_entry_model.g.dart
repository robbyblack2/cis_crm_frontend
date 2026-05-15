// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimelineEntryModel _$TimelineEntryModelFromJson(Map<String, dynamic> json) =>
    TimelineEntryModel(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      eventType: json['event_type'] as String,
      actorType: json['actor_type'] as String,
      actorId: json['actor_id'] as String,
      summary: json['summary'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TimelineEntryModelToJson(TimelineEntryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'entity_type': instance.entityType,
      'entity_id': instance.entityId,
      'event_type': instance.eventType,
      'actor_type': instance.actorType,
      'actor_id': instance.actorId,
      'summary': instance.summary,
      'created_at': instance.createdAt.toIso8601String(),
    };
