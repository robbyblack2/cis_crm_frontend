part of 'record_bloc.dart';

sealed class RecordEvent extends Equatable {
  const RecordEvent();

  @override
  List<Object?> get props => [];
}

final class RecordLoadRequested extends RecordEvent {
  const RecordLoadRequested();
}

final class RecordCreateRequested extends RecordEvent {
  const RecordCreateRequested({
    required this.pipelineId,
    required this.stageId,
    required this.title,
    required this.source,
  });

  final String pipelineId;
  final String stageId;
  final String title;
  final RecordSource source;

  @override
  List<Object?> get props => [pipelineId, stageId, title, source];
}

final class RecordMoveRequested extends RecordEvent {
  const RecordMoveRequested({
    required this.recordId,
    required this.toStageId,
  });

  final String recordId;
  final String toStageId;

  @override
  List<Object?> get props => [recordId, toStageId];
}
