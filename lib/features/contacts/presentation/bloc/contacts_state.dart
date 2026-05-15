part of 'contacts_bloc.dart';

@immutable
sealed class ContactsState extends Equatable {
  const ContactsState();

  @override
  List<Object?> get props => [];
}

final class ContactsInitial extends ContactsState {
  const ContactsInitial();
}

final class ContactsLoading extends ContactsState {
  const ContactsLoading();
}

final class ContactsLoaded extends ContactsState {
  const ContactsLoaded({required this.contacts});

  final List<Contact> contacts;

  @override
  List<Object?> get props => [contacts];
}

final class ContactsError extends ContactsState {
  const ContactsError({required this.failure});

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}
