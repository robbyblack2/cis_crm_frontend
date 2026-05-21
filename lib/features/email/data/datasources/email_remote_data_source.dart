import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/email/data/models/email_draft_model.dart';
import 'package:cis_crm/features/email/data/models/email_message_model.dart';
import 'package:cis_crm/features/email/data/models/email_template_model.dart';
import 'package:dio/dio.dart';

abstract interface class EmailRemoteDataSource {
  Future<EmailMessageModel> sendEmail({
    required List<String> recipientEmails,
    required String subject,
    required String body,
    String? contactId,
    String? recordId,
    List<String>? cc,
  });

  Future<EmailDraftModel> saveDraft({
    required List<String> recipientEmails,
    required String subject,
    required String body,
    String? contactId,
    String? recordId,
  });

  Future<List<EmailDraftModel>> getDrafts();

  Future<EmailDraftModel> updateDraft({
    required String id,
    required List<String> recipientEmails,
    required String subject,
    required String body,
  });

  Future<EmailMessageModel> sendDraft({required String id});

  Future<List<EmailTemplateModel>> getTemplates();

  Future<EmailTemplateModel> createTemplate({
    required String name,
    required String subjectTemplate,
    required String bodyTemplate,
  });

  Future<EmailTemplateModel> updateTemplate({
    required String id,
    required String name,
    required String subjectTemplate,
    required String bodyTemplate,
  });

  Future<void> deleteTemplate({required String id});
}

class EmailRemoteDataSourceImpl implements EmailRemoteDataSource {
  const EmailRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<EmailMessageModel> sendEmail({
    required List<String> recipientEmails,
    required String subject,
    required String body,
    String? contactId,
    String? recordId,
    List<String>? cc,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/email/send',
        data: {
          'to': recipientEmails,
          'subject': subject,
          'body_html': body,
          if (contactId != null) 'contact_id': contactId,
          if (recordId != null) 'record_id': recordId,
          if (cc != null && cc.isNotEmpty) 'cc': cc,
        },
      );
      return EmailMessageModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to send email',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<EmailDraftModel> saveDraft({
    required List<String> recipientEmails,
    required String subject,
    required String body,
    String? contactId,
    String? recordId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/email/draft',
        data: {
          'to': recipientEmails,
          'subject': subject,
          'body_html': body,
          if (contactId != null) 'contact_id': contactId,
          if (recordId != null) 'record_id': recordId,
        },
      );
      return EmailDraftModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to save draft',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<EmailDraftModel>> getDrafts() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/email/drafts');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list
          .cast<Map<String, dynamic>>()
          .map(EmailDraftModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to load drafts',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<EmailDraftModel> updateDraft({
    required String id,
    required List<String> recipientEmails,
    required String subject,
    required String body,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/email/drafts/$id',
        data: {
          'to': recipientEmails,
          'subject': subject,
          'body_html': body,
        },
      );
      return EmailDraftModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update draft',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<EmailMessageModel> sendDraft({required String id}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/email/drafts/$id/send',
      );
      return EmailMessageModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to send draft',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<EmailTemplateModel>> getTemplates() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/email/templates');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list
          .cast<Map<String, dynamic>>()
          .map(EmailTemplateModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to load templates',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<EmailTemplateModel> createTemplate({
    required String name,
    required String subjectTemplate,
    required String bodyTemplate,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/email/templates',
        data: {
          'name': name,
          'subject_template': subjectTemplate,
          'body_template': bodyTemplate,
        },
      );
      return EmailTemplateModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to create template',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<EmailTemplateModel> updateTemplate({
    required String id,
    required String name,
    required String subjectTemplate,
    required String bodyTemplate,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/email/templates/$id',
        data: {
          'name': name,
          'subject_template': subjectTemplate,
          'body_template': bodyTemplate,
        },
      );
      return EmailTemplateModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update template',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteTemplate({required String id}) async {
    try {
      await _dio.delete<void>('/api/email/templates/$id');
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete template',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
