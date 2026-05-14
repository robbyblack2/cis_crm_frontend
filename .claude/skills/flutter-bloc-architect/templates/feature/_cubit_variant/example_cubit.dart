import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../core/error/result.dart';
import '../domain/entities/example_entity.dart';
import '../domain/repositories/example_repository.dart';

part 'example_state.dart';

/// Cubit variant — use when the screen has no concurrent flows or
/// debounced input. Just `load()` and `refresh()` method calls.
///
/// Move to a `Bloc` if you find yourself needing to debounce, cancel
/// in-flight calls, or model multi-step interactions.
class ExampleCubit extends Cubit<ExampleState> {
  ExampleCubit(this._repository) : super(const ExampleInitial());

  final ExampleRepository _repository;

  Future<void> load() async {
    emit(const ExampleLoading());
    final result = await _repository.getAll();
    switch (result) {
      case Success(:final data):
        emit(ExampleLoaded(data));
      case Failure(:final error):
        emit(ExampleError(error));
    }
  }

  Future<void> refresh() async {
    final result = await _repository.getAll();
    switch (result) {
      case Success(:final data):
        emit(ExampleLoaded(data));
      case Failure(:final error):
        emit(ExampleError(error));
    }
  }
}
