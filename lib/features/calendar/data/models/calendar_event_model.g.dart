// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalendarEventModel _$CalendarEventModelFromJson(Map<String, dynamic> json) =>
    CalendarEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      googleEventId: json['google_event_id'] as String?,
      location: json['location'] as String?,
      meetingLink: json['meeting_link'] as String?,
      linkedRecordId: json['linked_record_id'] as String?,
    );

Map<String, dynamic> _$CalendarEventModelToJson(CalendarEventModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'google_event_id': instance.googleEventId,
      'title': instance.title,
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'location': instance.location,
      'meeting_link': instance.meetingLink,
      'linked_record_id': instance.linkedRecordId,
      'created_at': instance.createdAt.toIso8601String(),
    };
