import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:cis_crm/features/pipeline/domain/repositories/record_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'record_event.dart';
part 'record_state.dart';

class RecordBloc extends Bloc<RecordEvent, RecordState> {
  RecordBloc({required RecordRepository recordRepository})
      : _recordRepository = recordRepository,
        super(const RecordInitial()) {
    on<RecordLoadRequested>(_onLoadRequested, transformer: droppable());
    on<RecordCreateRequested>(_onCreateRequested, transformer: sequential());
    on<RecordMoveRequested>(_onMoveRequested, transformer: sequential());
  }

  final RecordRepository _recordRepository;

  Future<void> _onLoadRequested(
    RecordLoadRequested event,
    Emitter<RecordState> emit,
  ) async {
    emit(const RecordLoading());
    final result = await _recordRepository.getRecords();
    if (result.isSuccess) {
      emit(RecordLoaded(records: result.dataOrNull!));
    } else {
      emit(RecordError(message: result.failureOrNull!.message));
    }
  }

  Future<void> _onCreateRequested(
    RecordCreateRequested event,
    Emitter<RecordState> emit,
  ) async {
    emit(const RecordLoading());
    final result = await _recordRepository.createRecord(
      pipelineId: event.pipelineId,
      stageId: event.stageId,
      title: event.title,
      source: event.source,
    );
    if (result.isSuccess) {
      // Reload records after creation.
      final loadResult = await _recordRepository.getRecords();
      if (loadResult.isSuccess) {
        emit(RecordLoaded(records: loadResult.dataOrNull!));
      } else {
        emit(RecordError(message: loadResult.failureOrNull!.message));
      }
    } else {
      emit(RecordError(message: result.failureOrNull!.message));
    }
  }

  Future<void> _onMoveRequested(
    RecordMoveRequested event,
    Emitter<RecordState> emit,
  ) async {
    emit(const RecordLoading());
    final result = await _recordRepository.moveRecord(
      id: event.recordId,
      toStageId: event.toStageId,
    );
    if (result.isSuccess) {
      // Reload records after move.
      final loadResult = await _recordRepository.getRecords();
      if (loadResult.isSuccess) {
        emit(RecordLoaded(records: loadResult.dataOrNull!));
      } else {
        emit(RecordError(message: loadResult.failureOrNull!.message));
      }
    } else {
      emit(RecordError(message: result.failureOrNull!.message));
    }
  }
}
