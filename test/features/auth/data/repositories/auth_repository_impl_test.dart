import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/core/network/token_storage.dart';
import 'package:cis_crm/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:cis_crm/features/auth/data/models/user_model.dart';
import 'package:cis_crm/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cis_crm/features/auth/domain/entities/user.dart';
import 'package:cis_crm/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockTokenStorage extends Mock implements TokenStorage {}

const _testModel = UserModel(
  id: '1',
  email: 'test@example.com',
  displayName: 'Test User',
  status: UserStatus.active,
);

void main() {
  late _MockRemote remote;
  late _MockTokenStorage tokenStorage;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    tokenStorage = _MockTokenStorage();
    repository = AuthRepositoryImpl(
      remote: remote,
      tokenStorage: tokenStorage,
    );
  });

  tearDown(() {
    repository.dispose();
  });

  group('signIn', () {
    void setUpSuccessfulSignIn() {
      when(
        () => remote.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => 'test-jwt-token');
      when(
        () => tokenStorage.write(access: any(named: 'access')),
      ).thenAnswer((_) async {});
      when(() => remote.currentUser()).thenAnswer((_) async => _testModel);
    }

    test('returns Success(User) on successful sign in', () async {
      setUpSuccessfulSignIn();

      final result = await repository.signIn(
        email: 'test@example.com',
        password: 'password',
      );

      expect(result, isA<Success<User, AppFailure>>());
      expect(result.dataOrNull, _testModel);
      verify(() => tokenStorage.write(access: 'test-jwt-token')).called(1);
    });

    test('returns Failure(NetworkFailure) on NetworkException', () async {
      when(
        () => remote.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const NetworkException());

      final result = await repository.signIn(
        email: 'test@example.com',
        password: 'password',
      );

      expect(result, isA<Failure<User, AppFailure>>());
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('returns Failure(UnauthorizedFailure) on UnauthorizedException',
        () async {
      when(
        () => remote.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const UnauthorizedException('Invalid credentials.'));

      final result = await repository.signIn(
        email: 'test@example.com',
        password: 'wrong',
      );

      expect(result, isA<Failure<User, AppFailure>>());
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });

    test('returns Failure(ServerFailure) on ServerException', () async {
      when(
        () => remote.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const ServerException('Internal error', statusCode: 500));

      final result = await repository.signIn(
        email: 'test@example.com',
        password: 'password',
      );

      expect(result, isA<Failure<User, AppFailure>>());
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('emits authenticated on status stream after sign in', () async {
      setUpSuccessfulSignIn();

      // Start listening before signIn so we don't miss the event.
      final statuses = <AuthStatus>[];
      final sub = repository.status.listen(statuses.add);

      // Allow the async* generator to yield the initial unknown.
      await Future<void>.delayed(Duration.zero);

      await repository.signIn(
        email: 'test@example.com',
        password: 'password',
      );

      // Allow the stream to propagate.
      await Future<void>.delayed(Duration.zero);

      expect(statuses, contains(AuthStatus.authenticated));
      await sub.cancel();
    });
  });

  group('signOut', () {
    test('returns Success and clears tokens on sign out', () async {
      when(() => remote.signOut()).thenAnswer((_) async {});
      when(() => tokenStorage.clear()).thenAnswer((_) async {});

      final result = await repository.signOut();

      expect(result, isA<Success<void, AppFailure>>());
      verify(() => tokenStorage.clear()).called(1);
    });

    test('returns Failure(NetworkFailure) on NetworkException', () async {
      when(() => remote.signOut()).thenThrow(const NetworkException());

      final result = await repository.signOut();

      expect(result, isA<Failure<void, AppFailure>>());
      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('currentUser', () {
    test('returns Success(User) on success', () async {
      when(() => remote.currentUser()).thenAnswer((_) async => _testModel);

      final result = await repository.currentUser();

      expect(result, isA<Success<User, AppFailure>>());
      expect(result.dataOrNull, _testModel);
    });

    test(
        'returns Failure(UnauthorizedFailure) and emits unauthenticated on 401',
        () async {
      when(() => remote.currentUser()).thenThrow(const UnauthorizedException());

      final statuses = <AuthStatus>[];
      final sub = repository.status.listen(statuses.add);

      await Future<void>.delayed(Duration.zero);

      final result = await repository.currentUser();

      await Future<void>.delayed(Duration.zero);

      expect(result, isA<Failure<User, AppFailure>>());
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      expect(statuses, contains(AuthStatus.unauthenticated));
      await sub.cancel();
    });
  });
}
