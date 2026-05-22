import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/contacts/domain/entities/company.dart';
import 'package:cis_crm/features/contacts/domain/repositories/company_repository.dart';
import 'package:cis_crm/features/contacts/presentation/bloc/companies_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCompanyRepository extends Mock implements CompanyRepository {}

class FakeCompany extends Fake implements Company {}

void main() {
  late MockCompanyRepository mockRepo;

  final testCompanies = [
    Company(
      id: '1',
      name: 'Acme Corp',
      domain: 'acme.com',
      industry: 'Tech',
      tags: const ['vip'],
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
    Company(
      id: '2',
      name: 'Globex',
      domain: 'globex.com',
      industry: 'Manufacturing',
      tags: const [],
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
  ];

  setUpAll(() {
    registerFallbackValue(FakeCompany());
  });

  setUp(() {
    mockRepo = MockCompanyRepository();
  });

  group('CompaniesCubit', () {
    blocTest<CompaniesCubit, CompaniesState>(
      'emits [CompaniesLoading, CompaniesLoaded] when load succeeds',
      build: () {
        when(() => mockRepo.getCompanies())
            .thenAnswer((_) async => Success(testCompanies));
        return CompaniesCubit(companyRepository: mockRepo);
      },
      act: (cubit) => cubit.loadCompanies(),
      expect: () => [
        const CompaniesLoading(),
        CompaniesLoaded(companies: testCompanies),
      ],
    );

    blocTest<CompaniesCubit, CompaniesState>(
      'emits [CompaniesLoading, CompaniesError] when load fails',
      build: () {
        when(() => mockRepo.getCompanies()).thenAnswer(
          (_) async => const Failure(ServerFailure('Server error')),
        );
        return CompaniesCubit(companyRepository: mockRepo);
      },
      act: (cubit) => cubit.loadCompanies(),
      expect: () => [
        const CompaniesLoading(),
        isA<CompaniesError>(),
      ],
    );

    blocTest<CompaniesCubit, CompaniesState>(
      'reloads after successful create',
      build: () {
        when(() => mockRepo.createCompany(any()))
            .thenAnswer((_) async => Success(testCompanies.first));
        when(() => mockRepo.getCompanies())
            .thenAnswer((_) async => Success(testCompanies));
        return CompaniesCubit(companyRepository: mockRepo);
      },
      act: (cubit) => cubit.createCompany(testCompanies.first),
      expect: () => [
        const CompaniesLoading(),
        CompaniesLoaded(companies: testCompanies),
      ],
      verify: (_) {
        verify(() => mockRepo.createCompany(any())).called(1);
        verify(() => mockRepo.getCompanies()).called(1);
      },
    );

    blocTest<CompaniesCubit, CompaniesState>(
      'emits error when create fails',
      build: () {
        when(() => mockRepo.createCompany(any())).thenAnswer(
          (_) async => const Failure(ServerFailure('Create failed')),
        );
        return CompaniesCubit(companyRepository: mockRepo);
      },
      act: (cubit) => cubit.createCompany(testCompanies.first),
      expect: () => [isA<CompaniesError>()],
    );

    blocTest<CompaniesCubit, CompaniesState>(
      'reloads after successful delete',
      build: () {
        when(() => mockRepo.deleteCompany('1'))
            .thenAnswer((_) async => const Success(null));
        when(() => mockRepo.getCompanies())
            .thenAnswer((_) async => Success(testCompanies));
        return CompaniesCubit(companyRepository: mockRepo);
      },
      act: (cubit) => cubit.deleteCompany('1'),
      expect: () => [
        const CompaniesLoading(),
        CompaniesLoaded(companies: testCompanies),
      ],
      verify: (_) {
        verify(() => mockRepo.deleteCompany('1')).called(1);
      },
    );
  });
}
