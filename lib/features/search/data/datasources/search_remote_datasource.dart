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

      final response = await _dio.get<List<dynamic>>(
        '/api/search',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data == null) {
        throw const ServerException('Empty response from search API');
      }

      return data
          .cast<Map<String, dynamic>>()
          .map(SearchResultModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Search request failed',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
