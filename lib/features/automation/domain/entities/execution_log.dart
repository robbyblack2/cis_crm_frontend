import 'package:cis_crm/features/automation/domain/entities/execution_status.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class ExecutionLog extends Equatable {
  const ExecutionLog({
    required this.id,
    required this.ruleId,
    required this.correlationId,
    required this.status,
    required this.createdAt,
    this.errorDetail,
  });

  final String id;
  final String ruleId;
  final String correlationId;
  final ExecutionStatus status;
  final String? errorDetail;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        ruleId,
        correlationId,
        status,
        errorDetail,
        createdAt,
      ];
}
