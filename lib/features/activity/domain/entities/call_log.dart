import 'package:cis_crm/features/activity/domain/entities/call_direction.dart';
import 'package:cis_crm/features/activity/domain/entities/call_outcome.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class CallLog extends Equatable {
  const CallLog({
    required this.id,
    required this.contactId,
    required this.direction,
    required this.outcome,
    required this.loggedBy,
    required this.createdAt,
    this.recordId,
    this.durationSeconds,
    this.notes,
  });

  final String id;
  final String contactId;
  final String? recordId;
  final CallDirection direction;
  final CallOutcome outcome;
  final int? durationSeconds;
  final String? notes;
  final String loggedBy;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        contactId,
        recordId,
        direction,
        outcome,
        durationSeconds,
        notes,
        loggedBy,
        createdAt,
      ];
}
