import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/email/domain/entities/email_draft.dart';
import 'package:cis_crm/features/email/domain/entities/email_message.dart';
import 'package:cis_crm/features/email/domain/entities/email_template.dart';
import 'package:cis_crm/features/email/domain/repositories/email_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'email_event.dart';
part 'email_state.dart';

class EmailBloc extends Bloc<EmailEvent, EmailState> {
  EmailBloc({required EmailRepository emailRepository})
      : _emailRepository = emailRepository,
        super(const EmailInitial()) {
    on<EmailSendRequested>(_onEmailSendRequested, transformer: droppable());
    on<DraftSaveRequested>(_onDraftSaveRequested, transformer: droppable());
    on<DraftSendRequested>(_onDraftSendRequested, transformer: droppable());
    on<TemplatesLoadRequested>(
      _onTemplatesLoadRequested,
      transformer: restartable(),
    );
  }

  final EmailRepository _emailRepository;

  Future<void> _onEmailSendRequested(
    EmailSendRequested event,
    Emitter<EmailState> emit,
  ) async {
    emit(const EmailLoading());
    final result = await _emailRepository.sendEmail(
      recipientEmails: event.recipientEmails,
      subject: event.subject,
      body: event.body,
    );
    switch (result) {
      case Success(:final data):
        emit(EmailLoaded(sentMessage: data));
      case Failure(:final error):
        emit(EmailError(failure: error));
    }
  }

  Future<void> _onDraftSaveRequested(
    DraftSaveRequested event,
    Emitter<EmailState> emit,
  ) async {
    emit(const EmailLoading());
    final result = await _emailRepository.saveDraft(
      recipientEmails: event.recipientEmails,
      subject: event.subject,
      body: event.body,
    );
    switch (result) {
      case Success(:final data):
        emit(EmailLoaded(savedDraft: data));
      case Failure(:final error):
        emit(EmailError(failure: error));
    }
  }

  Future<void> _onDraftSendRequested(
    DraftSendRequested event,
    Emitter<EmailState> emit,
  ) async {
    emit(const EmailLoading());
    final result = await _emailRepository.sendDraft(id: event.draftId);
    switch (result) {
      case Success(:final data):
        emit(EmailLoaded(sentMessage: data));
      case Failure(:final error):
        emit(EmailError(failure: error));
    }
  }

  Future<void> _onTemplatesLoadRequested(
    TemplatesLoadRequested event,
    Emitter<EmailState> emit,
  ) async {
    emit(const EmailLoading());
    final result = await _emailRepository.getTemplates();
    switch (result) {
      case Success(:final data):
        emit(EmailLoaded(templates: data));
      case Failure(:final error):
        emit(EmailError(failure: error));
    }
  }
}
