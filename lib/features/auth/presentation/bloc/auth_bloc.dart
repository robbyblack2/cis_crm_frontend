import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/auth/data/models/user_model.dart';
import 'package:cis_crm/features/auth/domain/entities/user.dart';
import 'package:cis_crm/features/auth/domain/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends HydratedBloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthInitial()) {
    // Subscribe AFTER super() to avoid racing with rehydration.
    _statusSub = _repository.status.listen(
      (status) => add(_AuthStatusChanged(status)),
    );

    on<_AuthStatusChanged>(_onStatusChanged, transformer: sequential());
    on<AuthSignInRequested>(
      _onSignInRequested,
      transformer: droppable(),
    );
    on<AuthSignOutRequested>(
      _onSignOutRequested,
      transformer: droppable(),
    );
    on<AuthUserRefreshRequested>(
      _onUserRefreshRequested,
      transformer: droppable(),
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<AuthStatus> _statusSub;

  Future<void> _onStatusChanged(
    _AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
    switch (event.status) {
      case AuthStatus.unknown:
        return;
      case AuthStatus.authenticated:
        final result = await _repository.currentUser();
        switch (result) {
          case Success(:final data):
            emit(AuthAuthenticated(data));
          case Failure(:final error):
            emit(AuthError(error));
        }
      case AuthStatus.unauthenticated:
        emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.signIn(
      email: event.email,
      password: event.password,
    );
    switch (result) {
      case Success(:final data):
        emit(AuthAuthenticated(data));
      case Failure(:final error):
        emit(AuthError(error));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.signOut();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onUserRefreshRequested(
    AuthUserRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _repository.currentUser();
    switch (result) {
      case Success(:final data):
        emit(AuthAuthenticated(data));
      case Failure(:final error):
        emit(AuthError(error));
    }
  }

  // ── HydratedBloc serialization ────────────────────────────────

  @override
  AuthState? fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'authenticated' => AuthAuthenticated(
          UserModel.fromJson(
            json['user'] as Map<String, dynamic>,
          ),
        ),
      'unauthenticated' => const AuthUnauthenticated(),
      _ => null,
    };
  }

  @override
  Map<String, dynamic>? toJson(AuthState state) => switch (state) {
        AuthAuthenticated(:final user) => {
            'type': 'authenticated',
            'user': UserModel.fromEntity(user).toJson(),
          },
        AuthUnauthenticated() => {'type': 'unauthenticated'},
        AuthInitial() => null,
        AuthLoading() => null,
        AuthError() => null,
      };

  @override
  Future<void> close() {
    _statusSub.cancel();
    return super.close();
  }
}
