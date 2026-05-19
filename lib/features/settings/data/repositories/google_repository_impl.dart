import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/settings/data/datasources/google_remote_data_source.dart';
import 'package:cis_crm/features/settings/domain/entities/google_connection.dart';
import 'package:cis_crm/features/settings/domain/repositories/google_repository.dart';
import 'package:dio/dio.dart';

class GoogleRepositoryImpl implements GoogleRepository {
  const GoogleRepositoryImpl({
    required GoogleRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final GoogleRemoteDataSource _remoteDataSource;

  @override
  Future<Result<String, AppFailure>> getAuthUrl() async {
    try {
      final url = await _remoteDataSource.getAuthUrl();
      return Success(url);
    } on DioException catch (e) {
      return Failure(_mapDioException(e));
    } on AppException catch (e) {
      return Failure(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<GoogleConnection, AppFailure>> getStatus() async {
    try {
      final model = await _remoteDataSource.getStatus();
      return Success(model);
    } on DioException catch (e) {
      return Failure(_mapDioException(e));
    } on AppException catch (e) {
      return Failure(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<void, AppFailure>> disconnect() async {
    try {
      await _remoteDataSource.disconnect();
      return const Success(null);
    } on DioException catch (e) {
      return Failure(_mapDioException(e));
    } on AppException catch (e) {
      return Failure(ServerFailure(e.message));
    }
  }

  AppFailure _mapDioException(DioException e) {
    final error = e.error;
    if (error is NetworkException) {
      return const NetworkFailure();
    }
    if (error is UnauthorizedException) {
      return UnauthorizedFailure(error.message);
    }
    if (error is ServerException) {
      return ServerFailure(error.message, statusCode: error.statusCode);
    }
    return UnknownFailure(e.message ?? 'Unknown error');
  }
}
