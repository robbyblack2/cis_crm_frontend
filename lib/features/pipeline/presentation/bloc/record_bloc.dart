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

final class RecordLoadMoreRequested extends RecordEvent {
  const RecordLoadMoreRequested();
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

final class RecordUpdateRequested extends RecordEvent {
  const RecordUpdateRequested({
    required this.id,
    required this.title,
    this.tags,
  });

  final String id;
  final String title;
  final List<String>? tags;

  @override
  List<Object?> get props => [id, title, tags];
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
  const RecordLoaded({
    required this.records,
    required this.currentPage,
    required this.total,
    this.perPage = 25,
    this.isLoadingMore = false,
  });

  final List<PipelineRecord> records;
  final int currentPage;
  final int total;
  final int perPage;
  final bool isLoadingMore;

  bool get hasMore => currentPage * perPage < total;

  RecordLoaded copyWith({
    List<PipelineRecord>? records,
    int? currentPage,
    int? total,
    int? perPage,
    bool? isLoadingMore,
  }) {
    return RecordLoaded(
      records: records ?? this.records,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      perPage: perPage ?? this.perPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props =>
      [records, currentPage, total, perPage, isLoadingMore];
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
    on<RecordLoadMoreRequested>(_onLoadMore, transformer: droppable());
    on<RecordCreateRequested>(_onCreate, transformer: droppable());
    on<RecordMoveRequested>(_onMove, transformer: droppable());
    on<RecordUpdateRequested>(_onUpdate, transformer: droppable());
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
        emit(
          RecordLoaded(
            records: data.items,
            currentPage: data.page,
            total: data.total,
            perPage: data.perPage,
          ),
        );
      case Failure(:final error):
        emit(RecordError(message: error.message));
    }
  }

  Future<void> _onLoadMore(
    RecordLoadMoreRequested event,
    Emitter<RecordState> emit,
  ) async {
    final current = state;
    if (current is! RecordLoaded || !current.hasMore || current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    final result = await _repository.getRecords(page: current.currentPage + 1);
    switch (result) {
      case Success(:final data):
        emit(
          RecordLoaded(
            records: [...current.records, ...data.items],
            currentPage: data.page,
            total: data.total,
            perPage: data.perPage,
          ),
        );
      case Failure(:final error):
        emit(current.copyWith(isLoadingMore: false));
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
            emit(
              RecordLoaded(
                records: data.items,
                currentPage: data.page,
                total: data.total,
                perPage: data.perPage,
              ),
            );
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
            emit(
              RecordLoaded(
                records: data.items,
                currentPage: data.page,
                total: data.total,
                perPage: data.perPage,
              ),
            );
          case Failure(:final error):
            emit(RecordError(message: error.message));
        }
      case Failure(:final error):
        emit(RecordError(message: error.message));
    }
  }

  Future<void> _onUpdate(
    RecordUpdateRequested event,
    Emitter<RecordState> emit,
  ) async {
    emit(const RecordLoading());
    final result = await _repository.updateRecord(
      id: event.id,
      title: event.title,
      tags: event.tags,
    );
    switch (result) {
      case Success():
        final listResult = await _repository.getRecords();
        switch (listResult) {
          case Success(:final data):
            emit(
              RecordLoaded(
                records: data.items,
                currentPage: data.page,
                total: data.total,
                perPage: data.perPage,
              ),
            );
          case Failure(:final error):
            emit(RecordError(message: error.message));
        }
      case Failure(:final error):
        emit(RecordError(message: error.message));
    }
  }
}
