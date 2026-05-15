import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/search/data/datasources/search_remote_datasource.dart';
import 'package:cis_crm/features/search/domain/entities/search_result.dart';
import 'package:cis_crm/features/search/domain/repositories/search_repository.dart';

final class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl({required SearchRemoteDatasource datasource})
      : _datasource = datasource;

  final SearchRemoteDatasource _datasource;

  @override
  Future<Result<List<SearchResult>, AppFailure>> search({
    required String query,
    String? type,
  }) async {
    try {
      final results = await _datasource.search(query: query, type: type);
      return Success(results);
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
