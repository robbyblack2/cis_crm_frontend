import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/entities/crm_task.dart';
import 'package:cis_crm/features/activity/domain/repositories/task_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'tasks_event.dart';
part 'tasks_state.dart';

class TasksBloc extends Bloc<TasksEvent, TasksState> {
  TasksBloc({required TaskRepository taskRepository})
      : _taskRepository = taskRepository,
        super(const TasksInitial()) {
    on<TasksLoadRequested>(_onLoadRequested, transformer: restartable());
    on<TaskCreateRequested>(_onCreateRequested, transformer: droppable());
    on<TaskUpdateRequested>(_onUpdateRequested, transformer: droppable());
  }

  final TaskRepository _taskRepository;

  Future<void> _onLoadRequested(
    TasksLoadRequested event,
    Emitter<TasksState> emit,
  ) async {
    emit(const TasksLoading());
    final result = await _taskRepository.getTasks();
    switch (result) {
      case Success(data: final tasks):
        emit(TasksLoaded(tasks: tasks));
      case Failure(error: final failure):
        emit(TasksError(message: failure.message));
    }
  }

  Future<void> _onCreateRequested(
    TaskCreateRequested event,
    Emitter<TasksState> emit,
  ) async {
    emit(const TasksLoading());
    final result = await _taskRepository.createTask(event.task);
    switch (result) {
      case Success():
        final loadResult = await _taskRepository.getTasks();
        switch (loadResult) {
          case Success(data: final tasks):
            emit(TasksLoaded(tasks: tasks));
          case Failure(error: final failure):
            emit(TasksError(message: failure.message));
        }
      case Failure(error: final failure):
        emit(TasksError(message: failure.message));
    }
  }

  Future<void> _onUpdateRequested(
    TaskUpdateRequested event,
    Emitter<TasksState> emit,
  ) async {
    emit(const TasksLoading());
    final result = await _taskRepository.updateTask(event.task);
    switch (result) {
      case Success():
        final loadResult = await _taskRepository.getTasks();
        switch (loadResult) {
          case Success(data: final tasks):
            emit(TasksLoaded(tasks: tasks));
          case Failure(error: final failure):
            emit(TasksError(message: failure.message));
        }
      case Failure(error: final failure):
        emit(TasksError(message: failure.message));
    }
  }
}
