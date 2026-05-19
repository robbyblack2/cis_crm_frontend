part of 'email_bloc.dart';

@immutable
sealed class EmailEvent extends Equatable {
  const EmailEvent();

  @override
  List<Object?> get props => [];
}

final class EmailSendRequested extends EmailEvent {
  const EmailSendRequested({
    required this.recipientEmails,
    required this.subject,
    required this.body,
  });

  final List<String> recipientEmails;
  final String subject;
  final String body;

  @override
  List<Object?> get props => [recipientEmails, subject, body];
}

final class DraftSaveRequested extends EmailEvent {
  const DraftSaveRequested({
    required this.recipientEmails,
    required this.subject,
    required this.body,
  });

  final List<String> recipientEmails;
  final String subject;
  final String body;

  @override
  List<Object?> get props => [recipientEmails, subject, body];
}

final class DraftSendRequested extends EmailEvent {
  const DraftSendRequested({required this.draftId});

  final String draftId;

  @override
  List<Object?> get props => [draftId];
}

final class TemplateCreateRequested extends EmailEvent {
  const TemplateCreateRequested({
    required this.name,
    required this.subject,
    required this.body,
  });

  final String name;
  final String subject;
  final String body;

  @override
  List<Object?> get props => [name, subject, body];
}

final class TemplatesLoadRequested extends EmailEvent {
  const TemplatesLoadRequested();
}
