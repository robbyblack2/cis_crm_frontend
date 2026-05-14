import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../core/error/result.dart';
import '../data/models/example_model.dart';
import '../domain/entities/example_entity.dart';
import '../domain/repositories/example_repository.dart';

part 'example_event.dart';
part 'example_state.dart';

/// HydratedBloc variant — state survives app restart.
///
/// Use for auth, theme, settings, cart, onboarding flag, anything the user
/// expects to persist across app launches. The state must be JSON-serializable
/// — `toJson` and `fromJson` are required overrides.
///
/// `HydratedBloc.storage` MUST be initialized in `main.dart` before any
/// `HydratedBloc` is constructed (the template `main.dart` already does this).
class ExampleBloc extends HydratedBloc<ExampleEvent, ExampleState> {
  ExampleBloc(this._repository) : super(const ExampleInitial()) {
    on<ExampleLoadRequested>(_onLoadRequested, transformer: droppable());
    on<ExampleCleared>(
      (_, emit) => emit(const ExampleInitial()),
      transformer: droppable(),
    );
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

  // ── HydratedBloc serialization ────────────────────────────────
  // The state hierarchy is sealed, so we route by `type` discriminator.

  @override
  ExampleState? fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'initial' => const ExampleInitial(),
      'loading' => const ExampleLoading(),
      'loaded' => ExampleLoaded(
          (json['items'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(ExampleModel.fromJson)
              .toList(),
        ),
      // We don't persist error states — they reload from scratch.
      _ => null,
    };
  }

  @override
  Map<String, dynamic>? toJson(ExampleState state) {
    return switch (state) {
      ExampleInitial() => {'type': 'initial'},
      ExampleLoading() => {'type': 'loading'},
      ExampleLoaded(:final items) => {
          'type': 'loaded',
          'items': items.whereType<ExampleModel>().map((m) => m.toJson()).toList(),
        },
      ExampleError() => null, // skip persisting errors
    };
  }
}
