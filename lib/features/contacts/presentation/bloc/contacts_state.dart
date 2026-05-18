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
  const ContactsLoaded({
    required this.contacts,
    required this.currentPage,
    required this.total,
    this.perPage = 25,
    this.isLoadingMore = false,
  });

  final List<Contact> contacts;
  final int currentPage;
  final int total;
  final int perPage;
  final bool isLoadingMore;

  bool get hasMore => currentPage * perPage < total;

  ContactsLoaded copyWith({
    List<Contact>? contacts,
    int? currentPage,
    int? total,
    int? perPage,
    bool? isLoadingMore,
  }) {
    return ContactsLoaded(
      contacts: contacts ?? this.contacts,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      perPage: perPage ?? this.perPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props =>
      [contacts, currentPage, total, perPage, isLoadingMore];
}

final class ContactsError extends ContactsState {
  const ContactsError({required this.failure});

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}
