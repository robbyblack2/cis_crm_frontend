import 'dart:async';

import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/forms/inputs/email_input.dart';
import 'package:cis_crm/core/forms/inputs/password_input.dart';
import 'package:cis_crm/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

part 'login_form_state.dart';

class LoginFormCubit extends Cubit<LoginFormState> {
  LoginFormCubit() : super(const LoginFormState());

  void emailChanged(String value) {
    final email = EmailInput.dirty(value);
    emit(
      state.copyWith(
        email: email,
        status: FormzSubmissionStatus.initial,
        errorMessage: () => null,
      ),
    );
  }

  void passwordChanged(String value) {
    final password = PasswordInput.dirty(value);
    emit(
      state.copyWith(
        password: password,
        status: FormzSubmissionStatus.initial,
        errorMessage: () => null,
      ),
    );
  }

  Future<void> submitted() async {
    final email = EmailInput.dirty(state.email.value);
    final password = PasswordInput.dirty(state.password.value);

    emit(state.copyWith(email: email, password: password));

    if (!Formz.validate([email, password])) {
      emit(state.copyWith(status: FormzSubmissionStatus.failure));
      return;
    }

    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));

    try {
      final authBloc = getIt<AuthBloc>();

      // Listen for the auth result
      final completer = Completer<AuthState>();
      late StreamSubscription<AuthState> sub;
      sub = authBloc.stream.listen((authState) {
        if (authState is AuthAuthenticated ||
            authState is AuthError ||
            authState is AuthUnauthenticated) {
          if (!completer.isCompleted) completer.complete(authState);
          sub.cancel();
        }
      });

      // Fire the sign-in event
      authBloc.add(
        AuthSignInRequested(
          email: state.email.value,
          password: state.password.value,
        ),
      );

      // Wait for result (with timeout)
      final result = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => const AuthUnauthenticated(),
      );

      switch (result) {
        case AuthAuthenticated():
          emit(state.copyWith(status: FormzSubmissionStatus.success));
        case AuthError(:final failure):
          emit(
            state.copyWith(
              status: FormzSubmissionStatus.failure,
              errorMessage: () => failure.message,
            ),
          );
        default:
          emit(
            state.copyWith(
              status: FormzSubmissionStatus.failure,
              errorMessage: () => 'Sign in failed. Check credentials.',
            ),
          );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: FormzSubmissionStatus.failure,
          errorMessage: () => e.toString(),
        ),
      );
    }
  }
}
