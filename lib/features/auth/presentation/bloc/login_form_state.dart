part of 'login_form_cubit.dart';

class LoginFormState extends Equatable {
  const LoginFormState({
    this.email = const EmailInput.pure(),
    this.password = const PasswordInput.pure(),
    this.status = FormzSubmissionStatus.initial,
    this.errorMessage,
  });

  final EmailInput email;
  final PasswordInput password;
  final FormzSubmissionStatus status;
  final String? errorMessage;

  bool get isValid => Formz.validate([email, password]);

  LoginFormState copyWith({
    EmailInput? email,
    PasswordInput? password,
    FormzSubmissionStatus? status,
    String? Function()? errorMessage,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [email, password, status, errorMessage];
}
