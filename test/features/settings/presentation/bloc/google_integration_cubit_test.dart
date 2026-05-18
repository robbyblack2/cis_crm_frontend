import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/settings/domain/entities/google_connection.dart';
import 'package:cis_crm/features/settings/domain/repositories/google_repository.dart';
import 'package:cis_crm/features/settings/presentation/bloc/google_integration_cubit.dart';
import 'package:cis_crm/features/settings/presentation/bloc/google_integration_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoogleRepository extends Mock implements GoogleRepository {}

void main() {
  late MockGoogleRepository mockRepository;
  late GoogleIntegrationCubit cubit;

  const tConnection = GoogleConnection(
    connected: true,
    email: 'user@gmail.com',
  );

  setUp(() {
    mockRepository = MockGoogleRepository();
    cubit = GoogleIntegrationCubit(repository: mockRepository);
  });

  tearDown(() => cubit.close());

  test('initial state is GoogleIntegrationInitial', () {
    expect(cubit.state, const GoogleIntegrationInitial());
  });

  group('loadStatus', () {
    blocTest<GoogleIntegrationCubit, GoogleIntegrationState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(() => mockRepository.getStatus())
            .thenAnswer((_) async => const Success(tConnection));
        return cubit;
      },
      act: (c) => c.loadStatus(),
      expect: () => [
        const GoogleIntegrationLoading(),
        const GoogleIntegrationLoaded(tConnection),
      ],
    );

    blocTest<GoogleIntegrationCubit, GoogleIntegrationState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockRepository.getStatus()).thenAnswer(
          (_) async => const Failure(ServerFailure('Server error')),
        );
        return cubit;
      },
      act: (c) => c.loadStatus(),
      expect: () => [
        const GoogleIntegrationLoading(),
        const GoogleIntegrationError(ServerFailure('Server error')),
      ],
    );
  });

  group('connectGoogle', () {
    blocTest<GoogleIntegrationCubit, GoogleIntegrationState>(
      'emits [Loading] and returns auth URL on success',
      build: () {
        when(() => mockRepository.getAuthUrl()).thenAnswer(
          (_) async => const Success('https://accounts.google.com/auth'),
        );
        return cubit;
      },
      act: (c) async {
        final url = await c.connectGoogle();
        expect(url, 'https://accounts.google.com/auth');
      },
      expect: () => [
        const GoogleIntegrationLoading(),
      ],
    );

    blocTest<GoogleIntegrationCubit, GoogleIntegrationState>(
      'emits [Loading, Error] and returns null on failure',
      build: () {
        when(() => mockRepository.getAuthUrl()).thenAnswer(
          (_) async => const Failure(NetworkFailure()),
        );
        return cubit;
      },
      act: (c) async {
        final url = await c.connectGoogle();
        expect(url, isNull);
      },
      expect: () => [
        const GoogleIntegrationLoading(),
        const GoogleIntegrationError(NetworkFailure()),
      ],
    );
  });

  group('disconnectGoogle', () {
    blocTest<GoogleIntegrationCubit, GoogleIntegrationState>(
      'emits [Loading, Loaded(disconnected)] on success',
      build: () {
        when(() => mockRepository.disconnect())
            .thenAnswer((_) async => const Success(null));
        return cubit;
      },
      act: (c) => c.disconnectGoogle(),
      expect: () => [
        const GoogleIntegrationLoading(),
        const GoogleIntegrationLoaded(GoogleConnection.disconnected),
      ],
    );

    blocTest<GoogleIntegrationCubit, GoogleIntegrationState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockRepository.disconnect()).thenAnswer(
          (_) async => const Failure(ServerFailure('Server error')),
        );
        return cubit;
      },
      act: (c) => c.disconnectGoogle(),
      expect: () => [
        const GoogleIntegrationLoading(),
        const GoogleIntegrationError(ServerFailure('Server error')),
      ],
    );
  });
}
