import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:cis_crm/features/activity/domain/repositories/task_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ──────────────────────────────────────────────────────────────

@immutable
sealed class TasksEvent extends Equatable {
  const TasksEvent();

  @override
  List<Object?> get props => [];
}

final class TasksLoadRequested extends TasksEvent {
  const TasksLoadRequested();
}

final class TaskCreateRequested extends TasksEvent {
  const TaskCreateRequested({required this.task});

  final Activity task;

  @override
  List<Object?> get props => [task];
}

final class TaskUpdateRequested extends TasksEvent {
  const TaskUpdateRequested({required this.task});

  final Activity task;

  @override
  List<Object?> get props => [task];
}

final class TaskDeleted extends TasksEvent {
  const TaskDeleted(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

// ── State ───────────────────────────────────────────────────────────────

@immutable
sealed class TasksState extends Equatable {
  const TasksState();

  @override
  List<Object?> get props => [];
}

final class TasksInitial extends TasksState {
  const TasksInitial();
}

final class TasksLoading extends TasksState {
  const TasksLoading();
}

final class TasksLoaded extends TasksState {
  const TasksLoaded({required this.tasks});

  final List<Activity> tasks;

  @override
  List<Object?> get props => [tasks];
}

final class TasksError extends TasksState {
  const TasksError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ── Bloc ────────────────────────────────────────────────────────────────

class TasksBloc extends Bloc<TasksEvent, TasksState> {
  TasksBloc({required TaskRepository taskRepository})
      : _repository = taskRepository,
        super(const TasksInitial()) {
    on<TasksLoadRequested>(_onLoad, transformer: restartable());
    on<TaskCreateRequested>(_onCreateRequested, transformer: droppable());
    on<TaskUpdateRequested>(_onUpdateRequested, transformer: droppable());
    on<TaskDeleted>(_onDelete);
  }

  final TaskRepository _repository;

  Future<void> _onLoad(
    TasksLoadRequested event,
    Emitter<TasksState> emit,
  ) async {
    emit(const TasksLoading());
    final result = await _repository.getTasks();
    switch (result) {
      case Success(:final data):
        emit(TasksLoaded(tasks: data));
      case Failure(:final error):
        emit(TasksError(message: error.message));
    }
  }

  Future<void> _onCreateRequested(
    TaskCreateRequested event,
    Emitter<TasksState> emit,
  ) async {
    emit(const TasksLoading());
    final result = await _repository.createTask(event.task);
    switch (result) {
      case Success():
        final listResult = await _repository.getTasks();
        switch (listResult) {
          case Success(:final data):
            emit(TasksLoaded(tasks: data));
          case Failure(:final error):
            emit(TasksError(message: error.message));
        }
      case Failure(:final error):
        emit(TasksError(message: error.message));
    }
  }

  Future<void> _onUpdateRequested(
    TaskUpdateRequested event,
    Emitter<TasksState> emit,
  ) async {
    emit(const TasksLoading());
    final result = await _repository.updateTask(event.task);
    switch (result) {
      case Success():
        final listResult = await _repository.getTasks();
        switch (listResult) {
          case Success(:final data):
            emit(TasksLoaded(tasks: data));
          case Failure(:final error):
            emit(TasksError(message: error.message));
        }
      case Failure(:final error):
        emit(TasksError(message: error.message));
    }
  }

  Future<void> _onDelete(TaskDeleted event, Emitter<TasksState> emit) async {
    final result = await _repository.deleteTask(event.taskId);
    switch (result) {
      case Success():
        add(const TasksLoadRequested());
      case Failure(:final error):
        emit(TasksError(message: error.message));
    }
  }
}
