import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/contacts/domain/entities/contact.dart';
import 'package:cis_crm/features/contacts/domain/repositories/contact_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'contacts_event.dart';
part 'contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  ContactsBloc({required ContactRepository contactRepository})
      : _repository = contactRepository,
        super(const ContactsInitial()) {
    on<ContactsLoadRequested>(_onLoadRequested, transformer: restartable());
    on<ContactCreateRequested>(_onCreateRequested, transformer: droppable());
    on<ContactDeleteRequested>(_onDeleteRequested, transformer: droppable());
  }

  final ContactRepository _repository;

  Future<void> _onLoadRequested(
    ContactsLoadRequested event,
    Emitter<ContactsState> emit,
  ) async {
    emit(const ContactsLoading());
    final result = await _repository.getContacts();
    switch (result) {
      case Success(:final data):
        emit(ContactsLoaded(contacts: data));
      case Failure(:final error):
        emit(ContactsError(failure: error));
    }
  }

  Future<void> _onCreateRequested(
    ContactCreateRequested event,
    Emitter<ContactsState> emit,
  ) async {
    final result = await _repository.createContact(event.contact);
    switch (result) {
      case Success():
        add(const ContactsLoadRequested());
      case Failure(:final error):
        emit(ContactsError(failure: error));
    }
  }

  Future<void> _onDeleteRequested(
    ContactDeleteRequested event,
    Emitter<ContactsState> emit,
  ) async {
    final result = await _repository.deleteContact(event.contactId);
    switch (result) {
      case Success():
        add(const ContactsLoadRequested());
      case Failure(:final error):
        emit(ContactsError(failure: error));
    }
  }
}
