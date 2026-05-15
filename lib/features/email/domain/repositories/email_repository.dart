import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/email/domain/entities/email_draft.dart';
import 'package:cis_crm/features/email/domain/entities/email_message.dart';
import 'package:cis_crm/features/email/domain/entities/email_template.dart';

abstract interface class EmailRepository {
  Future<Result<EmailMessage, AppFailure>> sendEmail({
    required List<String> recipientEmails,
    required String subject,
    required String body,
  });

  Future<Result<EmailDraft, AppFailure>> saveDraft({
    required List<String> recipientEmails,
    required String subject,
    required String body,
  });

  Future<Result<List<EmailDraft>, AppFailure>> getDrafts();

  Future<Result<EmailDraft, AppFailure>> updateDraft({
    required String id,
    required List<String> recipientEmails,
    required String subject,
    required String body,
  });

  Future<Result<EmailMessage, AppFailure>> sendDraft({required String id});

  Future<Result<List<EmailTemplate>, AppFailure>> getTemplates();

  Future<Result<EmailTemplate, AppFailure>> createTemplate({
    required String name,
    required String subject,
    required String body,
  });

  Future<Result<EmailTemplate, AppFailure>> updateTemplate({
    required String id,
    required String name,
    required String subject,
    required String body,
  });

  Future<Result<void, AppFailure>> deleteTemplate({required String id});
}
