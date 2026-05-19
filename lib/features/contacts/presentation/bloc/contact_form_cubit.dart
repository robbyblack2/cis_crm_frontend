import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/core/forms/inputs/name_input.dart';
import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:cis_crm/features/contacts/domain/repositories/contact_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

part 'contact_form_state.dart';

class ContactFormCubit extends Cubit<ContactFormState> {
  ContactFormCubit({
    required ContactRepository contactRepository,
    Contact? existingContact,
  })  : _repository = contactRepository,
        _existingContact = existingContact,
        super(
          existingContact != null
              ? ContactFormState(
                  firstName: NameInput.dirty(existingContact.firstName),
                  lastName: NameInput.dirty(existingContact.lastName),
                  email: existingContact.email,
                  phone: existingContact.phone ?? '',
                  jobTitle: existingContact.jobTitle ?? '',
                  source: existingContact.source ?? '',
                  companyId: existingContact.companyId,
                )
              : const ContactFormState(),
        );

  final ContactRepository _repository;
  final Contact? _existingContact;

  /// Whether this cubit is editing an existing contact.
  bool get isEditing => _existingContact != null;

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

  void companyChanged(String? id, String? name) {
    emit(state.copyWith(
      companyId: () => id,
      companyName: () => name,
    ));
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
      final now = DateTime.now();
      final contact = Contact(
        id: _existingContact?.id ?? '',
        firstName: state.firstName.value,
        lastName: state.lastName.value,
        email: state.email,
        phone: state.phone.isNotEmpty ? state.phone : null,
        jobTitle: state.jobTitle.isNotEmpty ? state.jobTitle : null,
        source: state.source.isNotEmpty ? state.source : null,
        status: _existingContact?.status ?? 'lead',
        tags: _existingContact?.tags ?? const [],
        ownerId: _existingContact?.ownerId,
        companyId: state.companyId ?? _existingContact?.companyId,
        version: _existingContact?.version ?? 1,
        createdAt: _existingContact?.createdAt ?? now,
        updatedAt: now,
      );

      final Result<Contact, dynamic> result = isEditing
          ? await _repository.updateContact(contact)
          : await _repository.createContact(contact);

      switch (result) {
        case Success():
          emit(
            state.copyWith(submissionStatus: FormzSubmissionStatus.success),
          );
        case Failure(:final error):
          emit(
            state.copyWith(
              submissionStatus: FormzSubmissionStatus.failure,
              errorMessage: () => error.toString(),
            ),
          );
      }
    } catch (e) {
      emit(
        state.copyWith(
          submissionStatus: FormzSubmissionStatus.failure,
          errorMessage: () => e.toString(),
        ),
      );
    }
  }
}
