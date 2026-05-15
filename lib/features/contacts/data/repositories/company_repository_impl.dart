import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/contacts/data/datasources/company_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/models/company_model.dart';
import 'package:cis_crm/features/contacts/domain/entities/company.dart';
import 'package:cis_crm/features/contacts/domain/repositories/company_repository.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  CompanyRepositoryImpl({required this.remoteDataSource});

  final CompanyRemoteDataSource remoteDataSource;

  @override
  Future<Result<List<Company>, AppFailure>> getCompanies() async {
    try {
      final companies = await remoteDataSource.getCompanies();
      return Success(companies);
    } on AppException catch (e) {
      return Failure(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Company, AppFailure>> getCompany(String id) async {
    try {
      final company = await remoteDataSource.getCompany(id);
      return Success(company);
    } on AppException catch (e) {
      return Failure(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Company, AppFailure>> createCompany(Company company) async {
    try {
      final model = CompanyModel.fromEntity(company);
      final created = await remoteDataSource.createCompany(model);
      return Success(created);
    } on AppException catch (e) {
      return Failure(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Company, AppFailure>> updateCompany(Company company) async {
    try {
      final model = CompanyModel.fromEntity(company);
      final updated = await remoteDataSource.updateCompany(model);
      return Success(updated);
    } on AppException catch (e) {
      return Failure(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, AppFailure>> deleteCompany(String id) async {
    try {
      await remoteDataSource.deleteCompany(id);
      return const Success(null);
    } on AppException catch (e) {
      return Failure(_mapExceptionToFailure(e));
    }
  }

  AppFailure _mapExceptionToFailure(AppException exception) {
    return switch (exception) {
      NetworkException() => const NetworkFailure(),
      UnauthorizedException() => const UnauthorizedFailure(),
      ServerException(:final message, :final statusCode) =>
        ServerFailure(message, statusCode: statusCode),
      ValidationException(:final message, :final fieldErrors) =>
        ValidationFailure(message, fieldErrors: fieldErrors),
      CacheException(:final message) => CacheFailure(message),
    };
  }
}
