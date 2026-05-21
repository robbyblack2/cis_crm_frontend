import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class CalendarEvent extends Equatable {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.createdAt,
    this.googleEventId,
    this.location,
    this.meetingLink,
    this.conferenceProvider,
    this.conferenceData,
    this.linkedRecordId,
  });

  final String id;
  final String? googleEventId;
  final String title;
  final DateTime start;
  final DateTime end;
  final String? location;
  final String? meetingLink;
  final String? conferenceProvider;
  final Map<String, dynamic>? conferenceData;
  final String? linkedRecordId;
  final DateTime createdAt;

  bool get hasMeeting => meetingLink != null && meetingLink!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        googleEventId,
        title,
        start,
        end,
        location,
        meetingLink,
        conferenceProvider,
        conferenceData,
        linkedRecordId,
        createdAt,
      ];
}
