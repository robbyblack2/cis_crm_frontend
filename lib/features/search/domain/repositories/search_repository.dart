// ignore_for_file: one_member_abstracts

import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/search/domain/entities/search_result.dart';

abstract interface class SearchRepository {
  Future<Result<List<SearchResult>, AppFailure>> search({
    required String query,
    String? type,
  });
}
