part of 'email_bloc.dart';

@immutable
sealed class EmailState extends Equatable {
  const EmailState();

  @override
  List<Object?> get props => [];
}

final class EmailInitial extends EmailState {
  const EmailInitial();
}

final class EmailLoading extends EmailState {
  const EmailLoading();
}

final class EmailLoaded extends EmailState {
  const EmailLoaded({
    this.sentMessage,
    this.savedDraft,
    this.templates,
  });

  final EmailMessage? sentMessage;
  final EmailDraft? savedDraft;
  final List<EmailTemplate>? templates;

  @override
  List<Object?> get props => [sentMessage, savedDraft, templates];
}

final class EmailError extends EmailState {
  const EmailError({required this.failure});

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}
