import 'package:cis_crm/features/calendar/domain/entities/calendar_event.dart';
import 'package:json_annotation/json_annotation.dart';

part 'calendar_event_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
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

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventModelFromJson(json);

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

  Map<String, dynamic> toJson() => _$CalendarEventModelToJson(this);
}
