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
    super.conferenceProvider,
    super.conferenceData,
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
      meetingLink: json['meeting_url'] as String? ??
          json['meeting_link'] as String?,
      conferenceProvider: json['conference_provider'] as String?,
      conferenceData: json['conference_data'] as Map<String, dynamic>?,
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
        conferenceProvider: entity.conferenceProvider,
        conferenceData: entity.conferenceData,
        linkedRecordId: entity.linkedRecordId,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'start_time': start.toUtc().toIso8601String(),
        'end_time': end.toUtc().toIso8601String(),
        'attendees': <Map<String, dynamic>>[],
        if (location != null && location!.isNotEmpty) 'location': location,
        if (meetingLink != null && meetingLink!.isNotEmpty)
          'meeting_url': meetingLink,
        if (linkedRecordId != null) 'linked_record_id': linkedRecordId,
      };
}
