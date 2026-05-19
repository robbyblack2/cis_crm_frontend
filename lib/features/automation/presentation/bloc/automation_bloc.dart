import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/automation/domain/entities/automation_rule.dart';
import 'package:cis_crm/features/automation/domain/repositories/automation_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'automation_event.dart';
part 'automation_state.dart';

class AutomationBloc extends Bloc<AutomationEvent, AutomationState> {
  AutomationBloc({required AutomationRepository repository})
      : _repository = repository,
        super(const AutomationInitial()) {
    on<AutomationRulesLoadRequested>(
      _onRulesLoadRequested,
      transformer: restartable(),
    );
    on<AutomationRuleCreateRequested>(
      _onRuleCreateRequested,
      transformer: droppable(),
    );
    on<AutomationRuleToggleRequested>(
      _onRuleToggleRequested,
      transformer: sequential(),
    );
    on<AutomationRuleDeleteRequested>(
      _onRuleDeleteRequested,
      transformer: droppable(),
    );
  }

  final AutomationRepository _repository;

  Future<void> _onRulesLoadRequested(
    AutomationRulesLoadRequested event,
    Emitter<AutomationState> emit,
  ) async {
    emit(const AutomationLoading());
    final result = await _repository.getRules();
    switch (result) {
      case Success(:final data):
        emit(AutomationLoaded(rules: data));
      case Failure(:final error):
        emit(AutomationError(message: error.message));
    }
  }

  Future<void> _onRuleCreateRequested(
    AutomationRuleCreateRequested event,
    Emitter<AutomationState> emit,
  ) async {
    emit(const AutomationLoading());
    final result = await _repository.createRule(event.rule);
    switch (result) {
      case Success():
        final listResult = await _repository.getRules();
        switch (listResult) {
          case Success(:final data):
            emit(AutomationLoaded(rules: data));
          case Failure(:final error):
            emit(AutomationError(message: error.message));
        }
      case Failure(:final error):
        emit(AutomationError(message: error.message));
    }
  }

  Future<void> _onRuleToggleRequested(
    AutomationRuleToggleRequested event,
    Emitter<AutomationState> emit,
  ) async {
    emit(const AutomationLoading());
    final result = await _repository.toggleRule(event.ruleId);
    switch (result) {
      case Success():
        final listResult = await _repository.getRules();
        switch (listResult) {
          case Success(:final data):
            emit(AutomationLoaded(rules: data));
          case Failure(:final error):
            emit(AutomationError(message: error.message));
        }
      case Failure(:final error):
        emit(AutomationError(message: error.message));
    }
  }

  Future<void> _onRuleDeleteRequested(
    AutomationRuleDeleteRequested event,
    Emitter<AutomationState> emit,
  ) async {
    emit(const AutomationLoading());
    final result = await _repository.deleteRule(event.ruleId);
    switch (result) {
      case Success():
        final listResult = await _repository.getRules();
        switch (listResult) {
          case Success(:final data):
            emit(AutomationLoaded(rules: data));
          case Failure(:final error):
            emit(AutomationError(message: error.message));
        }
      case Failure(:final error):
        emit(AutomationError(message: error.message));
    }
  }
}
