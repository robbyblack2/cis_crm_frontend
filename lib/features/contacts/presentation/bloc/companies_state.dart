part of 'companies_cubit.dart';

@immutable
sealed class CompaniesState extends Equatable {
  const CompaniesState();

  @override
  List<Object?> get props => [];
}

final class CompaniesInitial extends CompaniesState {
  const CompaniesInitial();
}

final class CompaniesLoading extends CompaniesState {
  const CompaniesLoading();
}

final class CompaniesLoaded extends CompaniesState {
  const CompaniesLoaded({required this.companies});

  final List<Company> companies;

  @override
  List<Object?> get props => [companies];
}

final class CompaniesError extends CompaniesState {
  const CompaniesError({required this.failure});

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}
