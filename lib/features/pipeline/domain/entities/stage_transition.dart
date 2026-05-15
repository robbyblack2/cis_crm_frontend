import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class StageTransition extends Equatable {
  const StageTransition({
    required this.id,
    required this.recordId,
    required this.fromStageId,
    required this.toStageId,
    required this.transitionedBy,
    required this.createdAt,
  });

  final String id;
  final String recordId;
  final String fromStageId;
  final String toStageId;
  final String transitionedBy;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        recordId,
        fromStageId,
        toStageId,
        transitionedBy,
        createdAt,
      ];
}
