part of 'automation_bloc.dart';

@immutable
sealed class AutomationEvent extends Equatable {
  const AutomationEvent();

  @override
  List<Object?> get props => [];
}

final class AutomationRulesLoadRequested extends AutomationEvent {
  const AutomationRulesLoadRequested();
}

final class AutomationRuleCreateRequested extends AutomationEvent {
  const AutomationRuleCreateRequested({required this.rule});

  final AutomationRule rule;

  @override
  List<Object?> get props => [rule];
}

final class AutomationRuleToggleRequested extends AutomationEvent {
  const AutomationRuleToggleRequested({required this.ruleId});

  final String ruleId;

  @override
  List<Object?> get props => [ruleId];
}

final class AutomationRuleDeleteRequested extends AutomationEvent {
  const AutomationRuleDeleteRequested({required this.ruleId});

  final String ruleId;

  @override
  List<Object?> get props => [ruleId];
}
