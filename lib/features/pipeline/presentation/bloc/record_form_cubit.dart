import 'package:cis_crm/core/forms/inputs/required_text_input.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

part 'record_form_state.dart';

class RecordFormCubit extends Cubit<RecordFormState> {
  RecordFormCubit() : super(const RecordFormState());

  void titleChanged(String value) {
    emit(
      state.copyWith(
        title: RequiredTextInput.dirty(value),
        submissionStatus: FormzSubmissionStatus.initial,
      ),
    );
  }

  void pipelineIdChanged(String value) {
    emit(state.copyWith(pipelineId: value));
  }

  void stageIdChanged(String value) {
    emit(state.copyWith(stageId: value));
  }

  void contactIdChanged(String value) {
    emit(state.copyWith(contactId: value));
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
      // TODO(pipeline): call repository to create/update record
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
