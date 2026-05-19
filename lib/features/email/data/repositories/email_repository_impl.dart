import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/email/data/datasources/email_remote_data_source.dart';
import 'package:cis_crm/features/email/domain/entities/email_draft.dart';
import 'package:cis_crm/features/email/domain/entities/email_message.dart';
import 'package:cis_crm/features/email/domain/entities/email_template.dart';
import 'package:cis_crm/features/email/domain/repositories/email_repository.dart';

class EmailRepositoryImpl implements EmailRepository {
  const EmailRepositoryImpl({required EmailRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final EmailRemoteDataSource _remoteDataSource;

  @override
  Future<Result<EmailMessage, AppFailure>> sendEmail({
    required List<String> recipientEmails,
    required String subject,
    required String body,
    String? contactId,
    String? recordId,
    List<String>? cc,
  }) =>
      _guard(
        () => _remoteDataSource.sendEmail(
          recipientEmails: recipientEmails,
          subject: subject,
          body: body,
          contactId: contactId,
          recordId: recordId,
          cc: cc,
        ),
      );

  @override
  Future<Result<EmailDraft, AppFailure>> saveDraft({
    required List<String> recipientEmails,
    required String subject,
    required String body,
    String? contactId,
    String? recordId,
  }) =>
      _guard(
        () => _remoteDataSource.saveDraft(
          recipientEmails: recipientEmails,
          subject: subject,
          body: body,
          contactId: contactId,
          recordId: recordId,
        ),
      );

  @override
  Future<Result<List<EmailDraft>, AppFailure>> getDrafts() =>
      _guard(_remoteDataSource.getDrafts);

  @override
  Future<Result<EmailDraft, AppFailure>> updateDraft({
    required String id,
    required List<String> recipientEmails,
    required String subject,
    required String body,
  }) =>
      _guard(
        () => _remoteDataSource.updateDraft(
          id: id,
          recipientEmails: recipientEmails,
          subject: subject,
          body: body,
        ),
      );

  @override
  Future<Result<EmailMessage, AppFailure>> sendDraft({required String id}) =>
      _guard(() => _remoteDataSource.sendDraft(id: id));

  @override
  Future<Result<List<EmailTemplate>, AppFailure>> getTemplates() =>
      _guard(_remoteDataSource.getTemplates);

  @override
  Future<Result<EmailTemplate, AppFailure>> createTemplate({
    required String name,
    required String subject,
    required String body,
  }) =>
      _guard(
        () => _remoteDataSource.createTemplate(
          name: name,
          subject: subject,
          body: body,
        ),
      );

  @override
  Future<Result<EmailTemplate, AppFailure>> updateTemplate({
    required String id,
    required String name,
    required String subject,
    required String body,
  }) =>
      _guard(
        () => _remoteDataSource.updateTemplate(
          id: id,
          name: name,
          subject: subject,
          body: body,
        ),
      );

  @override
  Future<Result<void, AppFailure>> deleteTemplate({required String id}) =>
      _guard(() => _remoteDataSource.deleteTemplate(id: id));

  Future<Result<T, AppFailure>> _guard<T>(Future<T> Function() call) async {
    try {
      final data = await call();
      return Success(data);
    } on NetworkException catch (e) {
      return Failure(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Failure(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }
}
