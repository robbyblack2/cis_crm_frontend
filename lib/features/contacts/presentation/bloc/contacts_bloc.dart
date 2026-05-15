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
  ContactsBloc({required this.contactRepository})
      : super(const ContactsInitial()) {
    on<ContactsLoadRequested>(
      _onLoadRequested,
      transformer: droppable(),
    );
    on<ContactsRefreshRequested>(
      _onRefreshRequested,
      transformer: droppable(),
    );
    on<ContactCreateRequested>(
      _onCreateRequested,
      transformer: sequential(),
    );
    on<ContactDeleteRequested>(
      _onDeleteRequested,
      transformer: sequential(),
    );
  }

  final ContactRepository contactRepository;

  Future<void> _onLoadRequested(
    ContactsLoadRequested event,
    Emitter<ContactsState> emit,
  ) async {
    emit(const ContactsLoading());
    final result = await contactRepository.getContacts();
    switch (result) {
      case Success(:final data):
        emit(ContactsLoaded(contacts: data));
      case Failure(:final error):
        emit(ContactsError(failure: error));
    }
  }

  Future<void> _onRefreshRequested(
    ContactsRefreshRequested event,
    Emitter<ContactsState> emit,
  ) async {
    final result = await contactRepository.getContacts();
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
    final result = await contactRepository.createContact(event.contact);
    switch (result) {
      case Success():
        add(const ContactsRefreshRequested());
      case Failure(:final error):
        emit(ContactsError(failure: error));
    }
  }

  Future<void> _onDeleteRequested(
    ContactDeleteRequested event,
    Emitter<ContactsState> emit,
  ) async {
    final result = await contactRepository.deleteContact(event.contactId);
    switch (result) {
      case Success():
        add(const ContactsRefreshRequested());
      case Failure(:final error):
        emit(ContactsError(failure: error));
    }
  }
}
