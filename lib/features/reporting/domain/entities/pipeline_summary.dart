import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class PipelineStageSummary extends Equatable {
  const PipelineStageSummary({
    required this.stageId,
    required this.stageName,
    required this.count,
    required this.value,
  });

  final String stageId;
  final String stageName;
  final int count;
  final double value;

  @override
  List<Object?> get props => [stageId, stageName, count, value];
}

@immutable
class PipelineSummary extends Equatable {
  const PipelineSummary({
    required this.pipelineId,
    required this.totalRecords,
    required this.totalValue,
    required this.byStage,
  });

  final String pipelineId;
  final int totalRecords;
  final double totalValue;
  final List<PipelineStageSummary> byStage;

  @override
  List<Object?> get props => [pipelineId, totalRecords, totalValue, byStage];
}
