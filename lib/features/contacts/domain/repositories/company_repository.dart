import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/contacts/domain/entities/company.dart';

abstract class CompanyRepository {
  Future<Result<List<Company>, AppFailure>> getCompanies();
  Future<Result<Company, AppFailure>> getCompany(String id);
  Future<Result<Company, AppFailure>> createCompany(Company company);
  Future<Result<Company, AppFailure>> updateCompany(Company company);
  Future<Result<void, AppFailure>> deleteCompany(String id);
}
