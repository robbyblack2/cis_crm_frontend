part of 'contacts_bloc.dart';

@immutable
sealed class ContactsEvent extends Equatable {
  const ContactsEvent();

  @override
  List<Object?> get props => [];
}

final class ContactsLoadRequested extends ContactsEvent {
  const ContactsLoadRequested();
}

final class ContactsLoadMoreRequested extends ContactsEvent {
  const ContactsLoadMoreRequested();
}

final class ContactCreateRequested extends ContactsEvent {
  const ContactCreateRequested(this.contact);

  final Contact contact;

  @override
  List<Object?> get props => [contact];
}

final class ContactDeleteRequested extends ContactsEvent {
  const ContactDeleteRequested(this.contactId);

  final String contactId;

  @override
  List<Object?> get props => [contactId];
}
