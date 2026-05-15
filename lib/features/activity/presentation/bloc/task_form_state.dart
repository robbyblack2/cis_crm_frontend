part of 'task_form_cubit.dart';

class TaskFormState extends Equatable {
  const TaskFormState({
    this.title = const RequiredTextInput.pure(),
    this.description = '',
    this.priority = 'medium',
    this.dueDate,
    this.submissionStatus = FormzSubmissionStatus.initial,
    this.errorMessage,
  });

  final RequiredTextInput title;
  final String description;
  final String priority;
  final DateTime? dueDate;
  final FormzSubmissionStatus submissionStatus;
  final String? errorMessage;

  bool get isValid => Formz.validate([title]);

  TaskFormState copyWith({
    RequiredTextInput? title,
    String? description,
    String? priority,
    DateTime? Function()? dueDate,
    FormzSubmissionStatus? submissionStatus,
    String? Function()? errorMessage,
  }) {
    return TaskFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate != null ? dueDate() : this.dueDate,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        title,
        description,
        priority,
        dueDate,
        submissionStatus,
        errorMessage,
      ];
}
