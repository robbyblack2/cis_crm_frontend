import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum StageType { normal, won, lost }

@immutable
class Stage extends Equatable {
  const Stage({
    required this.id,
    required this.pipelineId,
    required this.name,
    required this.position,
    required this.stageType,
    required this.color,
  });

  final String id;
  final String pipelineId;
  final String name;
  final int position;
  final StageType stageType;
  final String color;

  @override
  List<Object?> get props => [id, pipelineId, name, position, stageType, color];
}
