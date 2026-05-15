part of 'automation_bloc.dart';

@immutable
sealed class AutomationState extends Equatable {
  const AutomationState();

  @override
  List<Object?> get props => [];
}

final class AutomationInitial extends AutomationState {
  const AutomationInitial();
}

final class AutomationLoading extends AutomationState {
  const AutomationLoading();
}

final class AutomationLoaded extends AutomationState {
  const AutomationLoaded({required this.rules});

  final List<AutomationRule> rules;

  @override
  List<Object?> get props => [rules];
}

final class AutomationError extends AutomationState {
  const AutomationError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
