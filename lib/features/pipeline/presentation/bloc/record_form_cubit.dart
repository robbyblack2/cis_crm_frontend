import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/core/forms/inputs/required_text_input.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:cis_crm/features/pipeline/domain/repositories/record_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

part 'record_form_state.dart';

class RecordFormCubit extends Cubit<RecordFormState> {
  RecordFormCubit({required RecordRepository recordRepository})
      : _repository = recordRepository,
        super(const RecordFormState());

  final RecordRepository _repository;

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

    final result = await _repository.createRecord(
      pipelineId: state.pipelineId,
      stageId: state.stageId,
      title: state.title.value,
      source: RecordSource.manual,
    );
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
