import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/auth/domain/entities/user.dart';
import 'package:cis_crm/features/auth/domain/repositories/auth_repository.dart';
import 'package:cis_crm/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockStorage extends Mock implements Storage {}

const _testUser = User(
  id: '1',
  email: 'test@example.com',
  displayName: 'Test User',
  status: UserStatus.active,
);

void main() {
  late _MockAuthRepository repository;
  late StreamController<AuthStatus> statusController;

  setUp(() {
    final storage = _MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    when(() => storage.delete(any())).thenAnswer((_) async {});
    when(storage.clear).thenAnswer((_) async {});
    HydratedBloc.storage = storage;

    repository = _MockAuthRepository();
    statusController = StreamController<AuthStatus>.broadcast();

    when(() => repository.status).thenAnswer(
      (_) => statusController.stream,
    );
  });

  tearDown(() {
    statusController.close();
  });

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on successful sign in',
      build: () {
        when(
          () => repository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Success(_testUser));
        return AuthBloc(repository);
      },
      act: (bloc) => bloc.add(
        const AuthSignInRequested(
          email: 'test@example.com',
          password: 'password',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthAuthenticated(_testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on failed sign in',
      build: () {
        when(
          () => repository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async =>
              const Failure(UnauthorizedFailure('Invalid credentials.')),
        );
        return AuthBloc(repository);
      },
      act: (bloc) => bloc.add(
        const AuthSignInRequested(
          email: 'test@example.com',
          password: 'wrong',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError(UnauthorizedFailure('Invalid credentials.')),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] on sign out',
      build: () {
        when(() => repository.signOut()).thenAnswer(
          (_) async => const Success(null),
        );
        return AuthBloc(repository);
      },
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthAuthenticated] when status stream emits authenticated',
      build: () {
        when(() => repository.currentUser()).thenAnswer(
          (_) async => const Success(_testUser),
        );
        return AuthBloc(repository);
      },
      act: (bloc) => statusController.add(AuthStatus.authenticated),
      expect: () => [const AuthAuthenticated(_testUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when status stream emits unauthenticated',
      build: () => AuthBloc(repository),
      act: (bloc) => statusController.add(AuthStatus.unauthenticated),
      expect: () => [const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthError] when status authenticated but currentUser fails',
      build: () {
        when(() => repository.currentUser()).thenAnswer(
          (_) async => const Failure(NetworkFailure()),
        );
        return AuthBloc(repository);
      },
      act: (bloc) => statusController.add(AuthStatus.authenticated),
      expect: () => [const AuthError(NetworkFailure())],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthAuthenticated] on user refresh success',
      build: () {
        when(() => repository.currentUser()).thenAnswer(
          (_) async => const Success(_testUser),
        );
        return AuthBloc(repository);
      },
      act: (bloc) => bloc.add(const AuthUserRefreshRequested()),
      expect: () => [const AuthAuthenticated(_testUser)],
    );
  });
}
