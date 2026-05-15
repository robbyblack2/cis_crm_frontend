part of 'contacts_bloc.dart';

@immutable
sealed class ContactsEvent extends Equatable {
  const ContactsEvent();
}

final class ContactsLoadRequested extends ContactsEvent {
  const ContactsLoadRequested();

  @override
  List<Object?> get props => [];
}

final class ContactsRefreshRequested extends ContactsEvent {
  const ContactsRefreshRequested();

  @override
  List<Object?> get props => [];
}

final class ContactCreateRequested extends ContactsEvent {
  const ContactCreateRequested({required this.contact});

  final Contact contact;

  @override
  List<Object?> get props => [contact];
}

final class ContactDeleteRequested extends ContactsEvent {
  const ContactDeleteRequested({required this.contactId});

  final String contactId;

  @override
  List<Object?> get props => [contactId];
}
