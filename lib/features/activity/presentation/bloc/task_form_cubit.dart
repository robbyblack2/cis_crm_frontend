import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/core/forms/inputs/required_text_input.dart';
import 'package:cis_crm/features/activity/domain/entities/crm_task.dart';
import 'package:cis_crm/features/activity/domain/entities/task_priority.dart';
import 'package:cis_crm/features/activity/domain/entities/task_status.dart';
import 'package:cis_crm/features/activity/domain/repositories/task_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

part 'task_form_state.dart';

class TaskFormCubit extends Cubit<TaskFormState> {
  TaskFormCubit({required TaskRepository taskRepository})
      : _repository = taskRepository,
        super(const TaskFormState());

  final TaskRepository _repository;

  void titleChanged(String value) {
    emit(
      state.copyWith(
        title: RequiredTextInput.dirty(value),
        submissionStatus: FormzSubmissionStatus.initial,
      ),
    );
  }

  void descriptionChanged(String value) {
    emit(state.copyWith(description: value));
  }

  void priorityChanged(String value) {
    emit(state.copyWith(priority: value));
  }

  void dueDateChanged(DateTime? value) {
    emit(state.copyWith(dueDate: () => value));
  }

  Future<void> submitted() async {
    final title = RequiredTextInput.dirty(state.title.value);

    emit(state.copyWith(title: title));

    if (!Formz.validate([title])) {
      emit(state.copyWith(submissionStatus: FormzSubmissionStatus.failure));
      return;
    }

    emit(state.copyWith(submissionStatus: FormzSubmissionStatus.inProgress));

    final now = DateTime.now();
    final task = CrmTask(
      id: '',
      title: state.title.value,
      description:
          state.description.isNotEmpty ? state.description : null,
      status: TaskStatus.todo,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == state.priority,
        orElse: () => TaskPriority.medium,
      ),
      dueDate: state.dueDate,
      parentType: 'general',
      parentId: '',
      createdBy: '',
      createdAt: now,
      updatedAt: now,
    );

    final result = await _repository.createTask(task);
    switch (result) {
      case Success():
        emit(state.copyWith(submissionStatus: FormzSubmissionStatus.success));
      case Failure(:final error):
        emit(
          state.copyWith(
            submissionStatus: FormzSubmissionStatus.failure,
            errorMessage: () => error.message,
          ),
        );
    }
  }
}
