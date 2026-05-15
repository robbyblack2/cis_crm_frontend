part of 'pipeline_bloc.dart';

@immutable
sealed class PipelineState extends Equatable {
  const PipelineState();

  @override
  List<Object?> get props => [];
}

final class PipelineInitial extends PipelineState {
  const PipelineInitial();
}

final class PipelineLoading extends PipelineState {
  const PipelineLoading();
}

final class PipelineLoaded extends PipelineState {
  const PipelineLoaded({
    required this.pipelines,
    this.kanbanPipeline,
    this.kanbanStages,
  });

  final List<Pipeline> pipelines;
  final Pipeline? kanbanPipeline;
  final List<Stage>? kanbanStages;

  @override
  List<Object?> get props => [pipelines, kanbanPipeline, kanbanStages];
}

final class PipelineError extends PipelineState {
  const PipelineError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
