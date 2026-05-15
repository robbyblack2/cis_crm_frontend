import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/auth/domain/entities/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

abstract class AuthRepository {
  Stream<AuthStatus> get status;

  Future<Result<User, AppFailure>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void, AppFailure>> signOut();

  Future<Result<User, AppFailure>> currentUser();
}
