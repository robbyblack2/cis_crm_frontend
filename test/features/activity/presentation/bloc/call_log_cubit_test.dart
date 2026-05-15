import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/domain/entities/call_direction.dart';
import 'package:cis_crm/features/activity/domain/entities/call_log.dart';
import 'package:cis_crm/features/activity/domain/entities/call_outcome.dart';
import 'package:cis_crm/features/activity/domain/repositories/call_log_repository.dart';
import 'package:cis_crm/features/activity/presentation/bloc/call_log_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCallLogRepository extends Mock implements CallLogRepository {}

class FakeCallLog extends Fake implements CallLog {}

void main() {
  late MockCallLogRepository mockRepo;

  final now = DateTime(2024);
  final testLog = CallLog(
    id: '1',
    contactId: 'c1',
    direction: CallDirection.outbound,
    outcome: CallOutcome.connected,
    loggedBy: 'user1',
    createdAt: now,
  );

  setUpAll(() {
    registerFallbackValue(FakeCallLog());
  });

  setUp(() {
    mockRepo = MockCallLogRepository();
  });

  group('CallLogCubit', () {
    test('initial state is CallLogInitial', () {
      final cubit = CallLogCubit(callLogRepository: mockRepo);
      expect(cubit.state, const CallLogInitial());
      cubit.close();
    });

    blocTest<CallLogCubit, CallLogState>(
      'emits [Loading, Loaded] when loadCallLogs succeeds',
      build: () {
        when(() => mockRepo.getCallLogs())
            .thenAnswer((_) async => Success([testLog]));
        return CallLogCubit(callLogRepository: mockRepo);
      },
      act: (cubit) => cubit.loadCallLogs(),
      expect: () => [
        const CallLogLoading(),
        CallLogLoaded(callLogs: [testLog]),
      ],
    );

    blocTest<CallLogCubit, CallLogState>(
      'emits [Loading, Error] when loadCallLogs fails',
      build: () {
        when(() => mockRepo.getCallLogs()).thenAnswer(
          (_) async => const Failure(ServerFailure('Server error')),
        );
        return CallLogCubit(callLogRepository: mockRepo);
      },
      act: (cubit) => cubit.loadCallLogs(),
      expect: () => [
        const CallLogLoading(),
        const CallLogError(message: 'Server error'),
      ],
    );

    blocTest<CallLogCubit, CallLogState>(
      'emits [Loading, Loaded] when logCall succeeds',
      build: () {
        when(() => mockRepo.logCall(any()))
            .thenAnswer((_) async => Success(testLog));
        when(() => mockRepo.getCallLogs())
            .thenAnswer((_) async => Success([testLog]));
        return CallLogCubit(callLogRepository: mockRepo);
      },
      act: (cubit) => cubit.logCall(testLog),
      expect: () => [
        const CallLogLoading(),
        CallLogLoaded(callLogs: [testLog]),
      ],
    );

    blocTest<CallLogCubit, CallLogState>(
      'emits [Loading, Error] when logCall fails',
      build: () {
        when(() => mockRepo.logCall(any())).thenAnswer(
          (_) async => const Failure(ServerFailure('Log failed')),
        );
        return CallLogCubit(callLogRepository: mockRepo);
      },
      act: (cubit) => cubit.logCall(testLog),
      expect: () => [
        const CallLogLoading(),
        const CallLogError(message: 'Log failed'),
      ],
    );
  });
}
