import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/pagination/paginated_response.dart';
import 'package:cis_crm/features/pipeline/data/models/record_model.dart';
import 'package:cis_crm/features/pipeline/data/models/stage_transition_model.dart';
import 'package:cis_crm/features/pipeline/domain/entities/record.dart';
import 'package:dio/dio.dart';

abstract class RecordRemoteDataSource {
  Future<PaginatedResponse<RecordModel>> getRecords({
    int page = 1,
    int perPage = 25,
  });

  Future<RecordModel> getRecord(String id);

  Future<RecordModel> createRecord({
    required String pipelineId,
    required String stageId,
    required String title,
    required RecordSource source,
    String? contactId,
    String? companyId,
    List<String> tags,
  });

  Future<RecordModel> updateRecord({
    required String id,
    required String title,
    List<String>? tags,
  });

  Future<void> deleteRecord(String id);

  Future<RecordModel> moveRecord({
    required String id,
    required String toStageId,
    Map<String, dynamic>? promptData,
  });

  Future<List<StageTransitionModel>> getStageHistory(String recordId);

  Future<List<Map<String, dynamic>>> getNotes(String recordId);
  Future<Map<String, dynamic>> addNote(String recordId, String body);
  Future<List<Map<String, dynamic>>> getLinkedContacts(String recordId);
  Future<void> linkContact(String recordId, String contactId, String role);
  Future<void> unlinkContact(String recordId, String contactId);
  Future<RecordModel> claimRecord(String recordId);
  Future<List<Map<String, dynamic>>> getEmails(String recordId);

  // Bulk operations
  Future<void> bulkMove(List<String> recordIds, String stageId);
  Future<void> bulkAssign(List<String> recordIds, String userId);
  Future<void> bulkTag(List<String> recordIds, List<String> tags);
  Future<void> bulkDelete(List<String> recordIds);
}

class RecordRemoteDataSourceImpl implements RecordRemoteDataSource {
  const RecordRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<PaginatedResponse<RecordModel>> getRecords({
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/records',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response body');
      }
      final data = (body['data'] as List<dynamic>?) ?? [];
      final meta = body['meta'] as Map<String, dynamic>? ?? {};
      final items =
          data.cast<Map<String, dynamic>>().map(RecordModel.fromJson).toList();
      return PaginatedResponse<RecordModel>(
        items: items,
        page: meta['page'] as int? ?? page,
        perPage: meta['per_page'] as int? ?? perPage,
        total: meta['total'] as int? ?? items.length,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch records',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<RecordModel> getRecord(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/records/$id');
      return RecordModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch record',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<RecordModel> createRecord({
    required String pipelineId,
    required String stageId,
    required String title,
    required RecordSource source,
    String? contactId,
    String? companyId,
    List<String> tags = const [],
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/records',
        data: {
          'pipeline_id': pipelineId,
          'stage_id': stageId,
          'data': {'title': title},
          'source': source.name,
          'tags': tags,
          if (contactId != null) 'contact_id': contactId,
          if (companyId != null) 'company_id': companyId,
        },
      );
      return RecordModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to create record',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<RecordModel> updateRecord({
    required String id,
    required String title,
    List<String>? tags,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/records/$id',
        data: {
          'title': title,
          if (tags != null) 'tags': tags,
        },
      );
      return RecordModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to update record',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteRecord(String id) async {
    try {
      await _dio.delete<void>('/api/records/$id');
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to delete record',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<RecordModel> moveRecord({
    required String id,
    required String toStageId,
    Map<String, dynamic>? promptData,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/records/$id/move',
        data: {
          'stage_id': toStageId,
          if (promptData != null && promptData.isNotEmpty)
            'prompt_data': promptData,
        },
      );
      return RecordModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to move record',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<StageTransitionModel>> getStageHistory(String recordId) async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>('/api/records/$recordId/stage-history');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list
          .cast<Map<String, dynamic>>()
          .map(StageTransitionModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch stage history',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getNotes(String recordId) async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>('/api/records/$recordId/notes');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch notes',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> addNote(
    String recordId,
    String body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/records/$recordId/internal-note',
        data: {'body': body},
      );
      return response.data!['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to add note',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLinkedContacts(
    String recordId,
  ) async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>('/api/records/$recordId/contacts');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch linked contacts',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> linkContact(
    String recordId,
    String contactId,
    String role,
  ) async {
    try {
      await _dio.post<void>(
        '/api/records/$recordId/contacts',
        data: {'contact_id': contactId, 'role': role},
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to link contact',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> unlinkContact(String recordId, String contactId) async {
    try {
      await _dio.delete<void>(
        '/api/records/$recordId/contacts',
        data: {'contact_id': contactId},
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to unlink contact',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<RecordModel> claimRecord(String recordId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/records/$recordId/claim',
      );
      return RecordModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to claim record',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEmails(String recordId) async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>('/api/records/$recordId/emails');
      final list = response.data?['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to fetch emails',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> bulkMove(List<String> recordIds, String stageId) async {
    try {
      await _dio.post<void>(
        '/api/records/bulk-move',
        data: {'record_ids': recordIds, 'stage_id': stageId},
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Bulk move failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> bulkAssign(
    List<String> recordIds,
    String userId,
  ) async {
    try {
      await _dio.post<void>(
        '/api/records/bulk-assign',
        data: {'record_ids': recordIds, 'owner_id': userId},
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Bulk assign failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> bulkTag(
    List<String> recordIds,
    List<String> tags,
  ) async {
    try {
      await _dio.post<void>(
        '/api/records/bulk-tag',
        data: {'record_ids': recordIds, 'tags': tags},
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Bulk tag failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> bulkDelete(List<String> recordIds) async {
    try {
      await _dio.post<void>(
        '/api/records/bulk-delete',
        data: {'record_ids': recordIds},
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Bulk delete failed',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
