// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// import 'package:my_flutter_app/core/error/failures.dart';
// import 'package:my_flutter_app/core/error/result.dart';
// import 'package:my_flutter_app/features/example/domain/entities/example_entity.dart';
// import 'package:my_flutter_app/features/example/domain/repositories/example_repository.dart';
// import 'package:my_flutter_app/features/example/presentation/bloc/example_bloc.dart';

class _MockExampleRepository extends Mock implements ExampleRepository {}

void main() {
  group('ExampleBloc', () {
    late ExampleRepository repository;

    setUp(() {
      repository = _MockExampleRepository();
    });

    final entities = [
      const ExampleEntity(id: '1', name: 'one'),
      const ExampleEntity(id: '2', name: 'two'),
    ];

    blocTest<ExampleBloc, ExampleState>(
      'emits [Loading, Loaded] on successful load',
      build: () {
        when(repository.getAll).thenAnswer(
          (_) async => Success(entities),
        );
        return ExampleBloc(repository);
      },
      act: (bloc) => bloc.add(const ExampleLoadRequested()),
      expect: () => [
        const ExampleLoading(),
        ExampleLoaded(entities),
      ],
      verify: (_) {
        verify(repository.getAll).called(1);
      },
    );

    blocTest<ExampleBloc, ExampleState>(
      'emits [Loading, Error] on repository failure',
      build: () {
        when(repository.getAll).thenAnswer(
          (_) async => const Failure(NetworkFailure()),
        );
        return ExampleBloc(repository);
      },
      act: (bloc) => bloc.add(const ExampleLoadRequested()),
      expect: () => [
        const ExampleLoading(),
        const ExampleError(NetworkFailure()),
      ],
    );

    blocTest<ExampleBloc, ExampleState>(
      'optimistically updates and rolls back on delete failure',
      build: () {
        when(() => repository.delete(any())).thenAnswer(
          (_) async => const Failure(ServerFailure('500')),
        );
        return ExampleBloc(repository);
      },
      seed: () => ExampleLoaded(entities),
      act: (bloc) => bloc.add(const ExampleDeleteRequested('1')),
      expect: () => [
        ExampleLoaded([entities[1]]),       // optimistic
        ExampleLoaded(entities),            // rollback
        const ExampleError(ServerFailure('500')),
      ],
    );
  });
}
