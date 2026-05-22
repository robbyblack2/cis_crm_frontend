import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/contacts/domain/entities/company.dart';
import 'package:cis_crm/features/contacts/domain/repositories/company_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'companies_state.dart';

class CompaniesCubit extends Cubit<CompaniesState> {
  CompaniesCubit({required CompanyRepository companyRepository})
      : _repository = companyRepository,
        super(const CompaniesInitial());

  final CompanyRepository _repository;

  Future<void> loadCompanies() async {
    emit(const CompaniesLoading());
    final result = await _repository.getCompanies();
    switch (result) {
      case Success(:final data):
        emit(CompaniesLoaded(companies: data));
      case Failure(:final error):
        emit(CompaniesError(failure: error));
    }
  }

  Future<void> createCompany(Company company) async {
    final result = await _repository.createCompany(company);
    switch (result) {
      case Success():
        await loadCompanies();
      case Failure(:final error):
        emit(CompaniesError(failure: error));
    }
  }

  Future<void> deleteCompany(String id) async {
    final result = await _repository.deleteCompany(id);
    switch (result) {
      case Success():
        await loadCompanies();
      case Failure(:final error):
        emit(CompaniesError(failure: error));
    }
  }
}
