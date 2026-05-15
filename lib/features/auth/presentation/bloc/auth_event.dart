part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class _AuthStatusChanged extends AuthEvent {
  const _AuthStatusChanged(this.status);

  final AuthStatus status;

  @override
  List<Object?> get props => [status];
}

final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

final class AuthUserRefreshRequested extends AuthEvent {
  const AuthUserRefreshRequested();
}
