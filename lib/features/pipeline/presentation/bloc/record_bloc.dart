import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:cis_crm/features/pipeline/domain/repositories/record_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ──────────────────────────────────────────────────────────────────

@immutable
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

// ── States ──────────────────────────────────────────────────────────────────

@immutable
sealed class RecordState extends Equatable {
  const RecordState();

  @override
  List<Object?> get props => [];
}

final class RecordInitial extends RecordState {
  const RecordInitial();
}

final class RecordLoading extends RecordState {
  const RecordLoading();
}

final class RecordLoaded extends RecordState {
  const RecordLoaded({required this.records});

  final List<PipelineRecord> records;

  @override
  List<Object?> get props => [records];
}

final class RecordError extends RecordState {
  const RecordError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ── Bloc ────────────────────────────────────────────────────────────────────

class RecordBloc extends Bloc<RecordEvent, RecordState> {
  RecordBloc({required RecordRepository recordRepository})
      : _repository = recordRepository,
        super(const RecordInitial()) {
    on<RecordLoadRequested>(_onLoad, transformer: restartable());
    on<RecordCreateRequested>(_onCreate, transformer: droppable());
    on<RecordMoveRequested>(_onMove, transformer: droppable());
  }

  final RecordRepository _repository;

  Future<void> _onLoad(
    RecordLoadRequested event,
    Emitter<RecordState> emit,
  ) async {
    emit(const RecordLoading());
    final result = await _repository.getRecords();
    switch (result) {
      case Success(:final data):
        emit(RecordLoaded(records: data));
      case Failure(:final error):
        emit(RecordError(message: error.message));
    }
  }

  Future<void> _onCreate(
    RecordCreateRequested event,
    Emitter<RecordState> emit,
  ) async {
    emit(const RecordLoading());
    final result = await _repository.createRecord(
      pipelineId: event.pipelineId,
      stageId: event.stageId,
      title: event.title,
      source: event.source,
    );
    switch (result) {
      case Success():
        final listResult = await _repository.getRecords();
        switch (listResult) {
          case Success(:final data):
            emit(RecordLoaded(records: data));
          case Failure(:final error):
            emit(RecordError(message: error.message));
        }
      case Failure(:final error):
        emit(RecordError(message: error.message));
    }
  }

  Future<void> _onMove(
    RecordMoveRequested event,
    Emitter<RecordState> emit,
  ) async {
    emit(const RecordLoading());
    final result = await _repository.moveRecord(
      id: event.recordId,
      toStageId: event.toStageId,
    );
    switch (result) {
      case Success():
        final listResult = await _repository.getRecords();
        switch (listResult) {
          case Success(:final data):
            emit(RecordLoaded(records: data));
          case Failure(:final error):
            emit(RecordError(message: error.message));
        }
      case Failure(:final error):
        emit(RecordError(message: error.message));
    }
  }
}
