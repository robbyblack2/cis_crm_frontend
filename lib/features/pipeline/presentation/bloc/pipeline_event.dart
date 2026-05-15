part of 'pipeline_bloc.dart';

sealed class PipelineEvent extends Equatable {
  const PipelineEvent();

  @override
  List<Object?> get props => [];
}

final class PipelineLoadRequested extends PipelineEvent {
  const PipelineLoadRequested();
}

final class PipelineKanbanRequested extends PipelineEvent {
  const PipelineKanbanRequested({required this.pipelineId});

  final String pipelineId;

  @override
  List<Object?> get props => [pipelineId];
}
