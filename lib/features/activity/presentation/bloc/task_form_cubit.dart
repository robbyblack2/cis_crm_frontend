import 'package:cis_crm/core/forms/inputs/required_text_input.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

part 'task_form_state.dart';

class TaskFormCubit extends Cubit<TaskFormState> {
  TaskFormCubit() : super(const TaskFormState());

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

    try {
      // TODO(activity): call repository to create/update task
      emit(state.copyWith(submissionStatus: FormzSubmissionStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          submissionStatus: FormzSubmissionStatus.failure,
          errorMessage: e.toString,
        ),
      );
    }
  }
}
