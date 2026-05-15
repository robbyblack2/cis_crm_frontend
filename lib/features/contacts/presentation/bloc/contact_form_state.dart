part of 'contact_form_cubit.dart';

class ContactFormState extends Equatable {
  const ContactFormState({
    this.firstName = const NameInput.pure(),
    this.lastName = const NameInput.pure(),
    this.email = '',
    this.phone = '',
    this.jobTitle = '',
    this.source = '',
    this.submissionStatus = FormzSubmissionStatus.initial,
    this.errorMessage,
  });

  final NameInput firstName;
  final NameInput lastName;
  final String email;
  final String phone;
  final String jobTitle;
  final String source;
  final FormzSubmissionStatus submissionStatus;
  final String? errorMessage;

  bool get isValid => Formz.validate([firstName, lastName]);

  ContactFormState copyWith({
    NameInput? firstName,
    NameInput? lastName,
    String? email,
    String? phone,
    String? jobTitle,
    String? source,
    FormzSubmissionStatus? submissionStatus,
    String? Function()? errorMessage,
  }) {
    return ContactFormState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      jobTitle: jobTitle ?? this.jobTitle,
      source: source ?? this.source,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        email,
        phone,
        jobTitle,
        source,
        submissionStatus,
        errorMessage,
      ];
}
