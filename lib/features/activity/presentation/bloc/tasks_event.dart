part of 'tasks_bloc.dart';

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

  final CrmTask task;

  @override
  List<Object?> get props => [task];
}

final class TaskUpdateRequested extends TasksEvent {
  const TaskUpdateRequested({required this.task});

  final CrmTask task;

  @override
  List<Object?> get props => [task];
}
