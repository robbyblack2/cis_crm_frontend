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
    this.linkedRecordId,
  });

  final String id;
  final String? googleEventId;
  final String title;
  final DateTime start;
  final DateTime end;
  final String? location;
  final String? meetingLink;
  final String? linkedRecordId;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        googleEventId,
        title,
        start,
        end,
        location,
        meetingLink,
        linkedRecordId,
        createdAt,
      ];
}
