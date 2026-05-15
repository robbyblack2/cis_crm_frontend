import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/automation/presentation/bloc/automation_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers.dart';

void main() {
  late MockAutomationRepository repository;

  setUp(() {
    repository = MockAutomationRepository();
  });

  setUpAll(() {
    registerFallbackValue(createTestRuleModel());
  });

  group('AutomationBloc', () {
    test('initial state is AutomationInitial', () {
      final bloc = AutomationBloc(repository: repository);
      expect(bloc.state, const AutomationInitial());
      bloc.close();
    });

    group('AutomationRulesLoadRequested', () {
      final rules = [createTestRuleModel()];

      blocTest<AutomationBloc, AutomationState>(
        'emits [Loading, Loaded] when getRules succeeds',
        build: () {
          when(() => repository.getRules()).thenAnswer(
            (_) async => Success(rules),
          );
          return AutomationBloc(repository: repository);
        },
        act: (bloc) => bloc.add(const AutomationRulesLoadRequested()),
        expect: () => [
          const AutomationLoading(),
          AutomationLoaded(rules: rules),
        ],
      );

      blocTest<AutomationBloc, AutomationState>(
        'emits [Loading, Error] when getRules fails',
        build: () {
          when(() => repository.getRules()).thenAnswer(
            (_) async => const Failure(ServerFailure('Server error')),
          );
          return AutomationBloc(repository: repository);
        },
        act: (bloc) => bloc.add(const AutomationRulesLoadRequested()),
        expect: () => [
          const AutomationLoading(),
          const AutomationError(message: 'Server error'),
        ],
      );
    });

    group('AutomationRuleCreateRequested', () {
      final rule = createTestRuleModel();
      final rules = [rule];

      blocTest<AutomationBloc, AutomationState>(
        'emits [Loading, Loaded] when createRule succeeds',
        build: () {
          when(() => repository.createRule(any())).thenAnswer(
            (_) async => Success(rule),
          );
          when(() => repository.getRules()).thenAnswer(
            (_) async => Success(rules),
          );
          return AutomationBloc(repository: repository);
        },
        act: (bloc) => bloc.add(AutomationRuleCreateRequested(rule: rule)),
        expect: () => [
          const AutomationLoading(),
          AutomationLoaded(rules: rules),
        ],
      );

      blocTest<AutomationBloc, AutomationState>(
        'emits [Loading, Error] when createRule fails',
        build: () {
          when(() => repository.createRule(any())).thenAnswer(
            (_) async => const Failure(ServerFailure('Create failed')),
          );
          return AutomationBloc(repository: repository);
        },
        act: (bloc) => bloc.add(AutomationRuleCreateRequested(rule: rule)),
        expect: () => [
          const AutomationLoading(),
          const AutomationError(message: 'Create failed'),
        ],
      );
    });

    group('AutomationRuleToggleRequested', () {
      final rule = createTestRuleModel();
      final rules = [rule];

      blocTest<AutomationBloc, AutomationState>(
        'emits [Loading, Loaded] when toggleRule succeeds',
        build: () {
          when(() => repository.toggleRule('rule-1')).thenAnswer(
            (_) async => Success(rule),
          );
          when(() => repository.getRules()).thenAnswer(
            (_) async => Success(rules),
          );
          return AutomationBloc(repository: repository);
        },
        act: (bloc) =>
            bloc.add(const AutomationRuleToggleRequested(ruleId: 'rule-1')),
        expect: () => [
          const AutomationLoading(),
          AutomationLoaded(rules: rules),
        ],
      );

      blocTest<AutomationBloc, AutomationState>(
        'emits [Loading, Error] when toggleRule fails',
        build: () {
          when(() => repository.toggleRule('rule-1')).thenAnswer(
            (_) async => const Failure(ServerFailure('Toggle failed')),
          );
          return AutomationBloc(repository: repository);
        },
        act: (bloc) =>
            bloc.add(const AutomationRuleToggleRequested(ruleId: 'rule-1')),
        expect: () => [
          const AutomationLoading(),
          const AutomationError(message: 'Toggle failed'),
        ],
      );
    });
  });
}
