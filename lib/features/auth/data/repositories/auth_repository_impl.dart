import 'dart:async';

import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/core/network/token_storage.dart';
import 'package:cis_crm/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:cis_crm/features/auth/domain/entities/user.dart';
import 'package:cis_crm/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStorage tokenStorage,
  })  : _remote = remote,
        _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;
  final _controller = StreamController<AuthStatus>.broadcast();

  @override
  Stream<AuthStatus> get status async* {
    yield AuthStatus.unknown;
    yield* _controller.stream;
  }

  @override
  Future<Result<User, AppFailure>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final accessToken =
          await _remote.signIn(email: email, password: password);
      await _tokenStorage.write(access: accessToken);
      final user = await _remote.currentUser();
      _controller.add(AuthStatus.authenticated);
      return Success(user);
    } on NetworkException {
      return const Failure(NetworkFailure());
    } on UnauthorizedException catch (e) {
      return Failure(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<void, AppFailure>> signOut() async {
    try {
      await _remote.signOut();
      await _tokenStorage.clear();
      _controller.add(AuthStatus.unauthenticated);
      return const Success(null);
    } on NetworkException {
      return const Failure(NetworkFailure());
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  @override
  Future<Result<User, AppFailure>> currentUser() async {
    try {
      final user = await _remote.currentUser();
      _controller.add(AuthStatus.authenticated);
      return Success(user);
    } on NetworkException {
      return const Failure(NetworkFailure());
    } on UnauthorizedException {
      _controller.add(AuthStatus.unauthenticated);
      return const Failure(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Failure(UnknownFailure(e.message));
    }
  }

  void dispose() {
    _controller.close();
  }
}
