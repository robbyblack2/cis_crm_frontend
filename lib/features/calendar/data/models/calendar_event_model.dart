import 'package:cis_crm/features/calendar/domain/entities/calendar_event.dart';

class CalendarEventModel extends CalendarEvent {
  const CalendarEventModel({
    required super.id,
    required super.title,
    required super.start,
    required super.end,
    required super.createdAt,
    super.googleEventId,
    super.location,
    super.meetingLink,
    super.linkedRecordId,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      start: DateTime.parse(
        json['start_time'] as String? ??
            json['start'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      end: DateTime.parse(
        json['end_time'] as String? ??
            json['end'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      googleEventId: json['google_event_id'] as String?,
      location: json['location'] as String?,
      meetingLink: json['meeting_link'] as String?,
      linkedRecordId: json['linked_record_id'] as String?,
    );
  }

  factory CalendarEventModel.fromEntity(CalendarEvent entity) =>
      CalendarEventModel(
        id: entity.id,
        title: entity.title,
        start: entity.start,
        end: entity.end,
        createdAt: entity.createdAt,
        googleEventId: entity.googleEventId,
        location: entity.location,
        meetingLink: entity.meetingLink,
        linkedRecordId: entity.linkedRecordId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'start_time': start.toIso8601String(),
        'end_time': end.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        if (googleEventId != null) 'google_event_id': googleEventId,
        if (location != null) 'location': location,
        if (meetingLink != null) 'meeting_link': meetingLink,
        if (linkedRecordId != null) 'linked_record_id': linkedRecordId,
      };
}
