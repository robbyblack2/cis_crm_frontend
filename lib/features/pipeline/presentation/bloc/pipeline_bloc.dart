import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cis_crm/features/pipeline/domain/entities/pipeline.dart';
import 'package:cis_crm/features/pipeline/domain/entities/stage.dart';
import 'package:cis_crm/features/pipeline/domain/repositories/pipeline_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'pipeline_event.dart';
part 'pipeline_state.dart';

class PipelineBloc extends Bloc<PipelineEvent, PipelineState> {
  PipelineBloc({required PipelineRepository pipelineRepository})
      : _pipelineRepository = pipelineRepository,
        super(const PipelineInitial()) {
    on<PipelineLoadRequested>(_onLoadRequested, transformer: droppable());
    on<PipelineKanbanRequested>(_onKanbanRequested, transformer: droppable());
  }

  final PipelineRepository _pipelineRepository;

  Future<void> _onLoadRequested(
    PipelineLoadRequested event,
    Emitter<PipelineState> emit,
  ) async {
    emit(const PipelineLoading());
    final result = await _pipelineRepository.getPipelines();
    if (result.isSuccess) {
      emit(PipelineLoaded(pipelines: result.dataOrNull!));
    } else {
      emit(PipelineError(message: result.failureOrNull!.message));
    }
  }

  Future<void> _onKanbanRequested(
    PipelineKanbanRequested event,
    Emitter<PipelineState> emit,
  ) async {
    emit(const PipelineLoading());
    final result = await _pipelineRepository.getKanban(event.pipelineId);
    if (result.isSuccess) {
      final data = result.dataOrNull!;
      emit(
        PipelineLoaded(
          pipelines: const [],
          kanbanPipeline: data.pipeline,
          kanbanStages: data.stages,
        ),
      );
    } else {
      emit(PipelineError(message: result.failureOrNull!.message));
    }
  }
}
