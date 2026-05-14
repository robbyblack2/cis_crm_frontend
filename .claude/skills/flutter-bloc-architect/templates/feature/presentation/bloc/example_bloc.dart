import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/example_entity.dart';
import '../../domain/repositories/example_repository.dart';

part 'example_event.dart';
part 'example_state.dart';

/// Bloc for the `example` feature.
///
/// Uses `bloc_concurrency` transformers explicitly:
///   - `droppable` on the load event to ignore duplicate loads while one is in flight
///   - `sequential` on mutations (create / delete) so they don't interleave
class ExampleBloc extends Bloc<ExampleEvent, ExampleState> {
  ExampleBloc(this._repository) : super(const ExampleInitial()) {
    on<ExampleLoadRequested>(_onLoadRequested, transformer: droppable());
    on<ExampleRefreshRequested>(_onRefreshRequested, transformer: droppable());
    on<ExampleCreateRequested>(_onCreateRequested, transformer: sequential());
    on<ExampleDeleteRequested>(_onDeleteRequested, transformer: sequential());
  }

  final ExampleRepository _repository;

  Future<void> _onLoadRequested(
    ExampleLoadRequested event,
    Emitter<ExampleState> emit,
  ) async {
    emit(const ExampleLoading());
    final result = await _repository.getAll();
    switch (result) {
      case Success(:final data):
        emit(ExampleLoaded(data));
      case Failure(:final error):
        emit(ExampleError(error));
    }
  }

  Future<void> _onRefreshRequested(
    ExampleRefreshRequested event,
    Emitter<ExampleState> emit,
  ) async {
    final result = await _repository.getAll();
    switch (result) {
      case Success(:final data):
        emit(ExampleLoaded(data));
      case Failure(:final error):
        // Keep current data visible on refresh failure; surface a side-effect
        // for snackbars via a BlocListener that watches for ExampleError.
        emit(ExampleError(error));
    }
  }

  Future<void> _onCreateRequested(
    ExampleCreateRequested event,
    Emitter<ExampleState> emit,
  ) async {
    // Optimistic update: assume success, roll back on failure.
    final current = state;
    if (current is ExampleLoaded) {
      emit(ExampleLoaded([...current.items, event.entity]));
    }

    final result = await _repository.create(event.entity);
    switch (result) {
      case Success():
        // Re-fetch to get the server-assigned id, or apply the returned entity.
        add(const ExampleRefreshRequested());
      case Failure(:final error):
        if (current is ExampleLoaded) {
          emit(current); // rollback
        }
        emit(ExampleError(error));
    }
  }

  Future<void> _onDeleteRequested(
    ExampleDeleteRequested event,
    Emitter<ExampleState> emit,
  ) async {
    final current = state;
    if (current is ExampleLoaded) {
      emit(
        ExampleLoaded(
          current.items.where((e) => e.id != event.id).toList(growable: false),
        ),
      );
    }

    final result = await _repository.delete(event.id);
    switch (result) {
      case Success():
        // already optimistically applied
        break;
      case Failure(:final error):
        if (current is ExampleLoaded) {
          emit(current); // rollback
        }
        emit(ExampleError(error));
    }
  }
}
