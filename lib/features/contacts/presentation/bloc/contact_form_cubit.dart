import 'package:cis_crm/core/forms/inputs/name_input.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

part 'contact_form_state.dart';

class ContactFormCubit extends Cubit<ContactFormState> {
  ContactFormCubit() : super(const ContactFormState());

  void firstNameChanged(String value) {
    emit(
      state.copyWith(
        firstName: NameInput.dirty(value),
        submissionStatus: FormzSubmissionStatus.initial,
      ),
    );
  }

  void lastNameChanged(String value) {
    emit(
      state.copyWith(
        lastName: NameInput.dirty(value),
        submissionStatus: FormzSubmissionStatus.initial,
      ),
    );
  }

  void emailChanged(String value) {
    emit(state.copyWith(email: value));
  }

  void phoneChanged(String value) {
    emit(state.copyWith(phone: value));
  }

  void jobTitleChanged(String value) {
    emit(state.copyWith(jobTitle: value));
  }

  void sourceChanged(String value) {
    emit(state.copyWith(source: value));
  }

  Future<void> submitted() async {
    final firstName = NameInput.dirty(state.firstName.value);
    final lastName = NameInput.dirty(state.lastName.value);

    emit(state.copyWith(firstName: firstName, lastName: lastName));

    if (!Formz.validate([firstName, lastName])) {
      emit(state.copyWith(submissionStatus: FormzSubmissionStatus.failure));
      return;
    }

    emit(state.copyWith(submissionStatus: FormzSubmissionStatus.inProgress));

    try {
      // TODO(contacts): call repository to create/update contact
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
