import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class TimelineEntry extends Equatable {
  const TimelineEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.eventType,
    required this.actorType,
    required this.actorId,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String eventType;
  final String actorType;
  final String actorId;
  final String summary;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        entityType,
        entityId,
        eventType,
        actorType,
        actorId,
        summary,
        createdAt,
      ];
}
