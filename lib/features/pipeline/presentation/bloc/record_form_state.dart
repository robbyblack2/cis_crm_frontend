part of 'record_form_cubit.dart';

class RecordFormState extends Equatable {
  const RecordFormState({
    this.title = const RequiredTextInput.pure(),
    this.pipelineId = '',
    this.stageId = '',
    this.contactId = '',
    this.submissionStatus = FormzSubmissionStatus.initial,
    this.errorMessage,
  });

  final RequiredTextInput title;
  final String pipelineId;
  final String stageId;
  final String contactId;
  final FormzSubmissionStatus submissionStatus;
  final String? errorMessage;

  bool get isValid => Formz.validate([title]);

  RecordFormState copyWith({
    RequiredTextInput? title,
    String? pipelineId,
    String? stageId,
    String? contactId,
    FormzSubmissionStatus? submissionStatus,
    String? Function()? errorMessage,
  }) {
    return RecordFormState(
      title: title ?? this.title,
      pipelineId: pipelineId ?? this.pipelineId,
      stageId: stageId ?? this.stageId,
      contactId: contactId ?? this.contactId,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        title,
        pipelineId,
        stageId,
        contactId,
        submissionStatus,
        errorMessage,
      ];
}
