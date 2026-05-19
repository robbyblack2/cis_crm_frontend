import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class SyncRule extends Equatable {
  const SyncRule({
    required this.id,
    required this.name,
    required this.calendarId,
    required this.targetPipelineId,
    required this.targetStageId,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    this.matchCriteria,
    this.fieldMappings,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String calendarId;
  final String targetPipelineId;
  final String targetStageId;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? matchCriteria;
  final Map<String, dynamic>? fieldMappings;

  @override
  List<Object?> get props => [
        id,
        name,
        calendarId,
        targetPipelineId,
        targetStageId,
        isActive,
        createdBy,
        createdAt,
        updatedAt,
        matchCriteria,
        fieldMappings,
      ];
}
