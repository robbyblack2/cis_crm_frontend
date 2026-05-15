import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/search/domain/entities/search_result.dart';
import 'package:cis_crm/features/search/domain/repositories/search_repository.dart';
import 'package:cis_crm/features/search/presentation/bloc/search_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSearchRepository extends Mock implements SearchRepository {}

void main() {
  late MockSearchRepository mockRepository;

  setUp(() {
    mockRepository = MockSearchRepository();
  });

  const tResults = [
    SearchResult(
      id: '1',
      entityType: 'contact',
      title: 'John Doe',
      subtitle: 'john@example.com',
      matchedField: 'name',
    ),
    SearchResult(
      id: '2',
      entityType: 'deal',
      title: 'Big Deal',
    ),
  ];

  group('SearchBloc', () {
    test('initial state is SearchInitial', () {
      final bloc = SearchBloc(repository: mockRepository);
      expect(bloc.state, const SearchInitial());
      bloc.close();
    });

    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchLoaded] when search succeeds with results',
      build: () {
        when(
          () => mockRepository.search(query: any(named: 'query')),
        ).thenAnswer((_) async => const Success(tResults));
        return SearchBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SearchQueryChanged(query: 'john')),
      expect: () => [
        const SearchLoading(),
        const SearchLoaded(results: tResults, query: 'john'),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchEmpty] when search returns empty list',
      build: () {
        when(
          () => mockRepository.search(query: any(named: 'query')),
        ).thenAnswer((_) async => const Success([]));
        return SearchBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SearchQueryChanged(query: 'xyz')),
      expect: () => [
        const SearchLoading(),
        const SearchEmpty(query: 'xyz'),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchLoading, SearchError] when search fails',
      build: () {
        when(
          () => mockRepository.search(query: any(named: 'query')),
        ).thenAnswer(
          (_) async => const Failure(ServerFailure('Server error')),
        );
        return SearchBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SearchQueryChanged(query: 'fail')),
      expect: () => [
        const SearchLoading(),
        const SearchError(failure: ServerFailure('Server error')),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchInitial] when empty query is submitted',
      build: () => SearchBloc(repository: mockRepository),
      act: (bloc) => bloc.add(const SearchQueryChanged(query: '  ')),
      expect: () => const <SearchState>[],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [SearchInitial] when SearchCleared is added',
      build: () => SearchBloc(repository: mockRepository),
      seed: () => const SearchLoaded(results: tResults, query: 'john'),
      act: (bloc) => bloc.add(const SearchCleared()),
      expect: () => [const SearchInitial()],
    );

    blocTest<SearchBloc, SearchState>(
      'passes type parameter to repository when provided',
      build: () {
        when(
          () => mockRepository.search(
            query: any(named: 'query'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((_) async => const Success(tResults));
        return SearchBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(
        const SearchQueryChanged(query: 'john', type: 'contact'),
      ),
      expect: () => [
        const SearchLoading(),
        const SearchLoaded(results: tResults, query: 'john'),
      ],
      verify: (_) {
        verify(
          () => mockRepository.search(query: 'john', type: 'contact'),
        ).called(1);
      },
    );
  });
}
