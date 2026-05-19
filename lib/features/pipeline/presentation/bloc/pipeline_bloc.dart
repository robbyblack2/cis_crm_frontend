import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/pipeline/domain/entities/pipeline.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage.dart';
import 'package:cis_crm/features/pipeline/domain/repositories/pipeline_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ──────────────────────────────────────────────────────────────────

@immutable
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

// ── States ──────────────────────────────────────────────────────────────────

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

// ── Bloc ────────────────────────────────────────────────────────────────────

class PipelineBloc extends Bloc<PipelineEvent, PipelineState> {
  PipelineBloc({required PipelineRepository pipelineRepository})
      : _repository = pipelineRepository,
        super(const PipelineInitial()) {
    on<PipelineLoadRequested>(_onLoad, transformer: restartable());
    on<PipelineKanbanRequested>(_onKanban, transformer: restartable());
  }

  final PipelineRepository _repository;

  Future<void> _onLoad(
    PipelineLoadRequested event,
    Emitter<PipelineState> emit,
  ) async {
    emit(const PipelineLoading());
    final result = await _repository.getPipelines();
    switch (result) {
      case Success(:final data):
        emit(PipelineLoaded(pipelines: data));
      case Failure(:final error):
        emit(PipelineError(message: error.message));
    }
  }

  Future<void> _onKanban(
    PipelineKanbanRequested event,
    Emitter<PipelineState> emit,
  ) async {
    // Preserve the pipeline list from previous load.
    final currentPipelines = state is PipelineLoaded
        ? (state as PipelineLoaded).pipelines
        : <Pipeline>[];

    emit(const PipelineLoading());
    final result = await _repository.getKanban(event.pipelineId);
    switch (result) {
      case Success(:final data):
        emit(
          PipelineLoaded(
            pipelines: currentPipelines,
            kanbanPipeline: data.pipeline,
            kanbanStages: data.stages,
          ),
        );
      case Failure(:final error):
        emit(PipelineError(message: error.message));
    }
  }
}
