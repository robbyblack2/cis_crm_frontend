// ignore_for_file: one_member_abstracts

import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/features/search/data/models/search_result_model.dart';
import 'package:dio/dio.dart';

abstract interface class SearchRemoteDatasource {
  Future<List<SearchResultModel>> search({
    required String query,
    String? type,
  });
}

final class SearchRemoteDatasourceImpl implements SearchRemoteDatasource {
  const SearchRemoteDatasourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<SearchResultModel>> search({
    required String query,
    String? type,
  }) async {
    try {
      final queryParams = <String, dynamic>{'q': query};
      if (type != null) {
        queryParams['type'] = type;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/search',
        queryParameters: queryParams,
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from search API');
      }

      final data = body['data'] as Map<String, dynamic>? ?? {};
      final results = <SearchResultModel>[];

      final contacts = data['contacts'] as List<dynamic>? ?? [];
      for (final item in contacts) {
        final json = item as Map<String, dynamic>;
        json['entity_type'] = 'contact';
        results.add(SearchResultModel.fromJson(json));
      }

      final companies = data['companies'] as List<dynamic>? ?? [];
      for (final item in companies) {
        final json = item as Map<String, dynamic>;
        json['entity_type'] = 'company';
        results.add(SearchResultModel.fromJson(json));
      }

      return results;
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Search request failed',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
