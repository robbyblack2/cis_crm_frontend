import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/data/models/activity_model.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:cis_crm/features/activity/domain/repositories/call_log_repository.dart';
import 'package:cis_crm/features/activity/presentation/bloc/call_log_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCallLogRepository extends Mock implements CallLogRepository {}

class _FakeActivity extends Fake implements Activity {}

final _call = ActivityModel(
  id: 'call-1',
  activityType: ActivityType.call,
  title: 'Discovery call',
  statusId: 's1',
  statusName: 'Planned',
  statusPhase: 'open',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  data: const {'direction': 'outbound'},
);

void main() {
  late _MockCallLogRepository repository;

  setUpAll(() {
    registerFallbackValue(_FakeActivity());
  });

  setUp(() {
    repository = _MockCallLogRepository();
  });

  group('CallLogCubit', () {
    blocTest<CallLogCubit, CallLogState>(
      'emits [loading, loaded] on successful loadCallLogs',
      build: () {
        when(() => repository.getCallLogs())
            .thenAnswer((_) async => Success([_call]));
        return CallLogCubit(callLogRepository: repository);
      },
      act: (cubit) => cubit.loadCallLogs(),
      expect: () => [
        const CallLogLoading(),
        isA<CallLogLoaded>().having((s) => s.callLogs.length, 'count', 1),
      ],
    );

    blocTest<CallLogCubit, CallLogState>(
      'emits [loading, error] on failed loadCallLogs',
      build: () {
        when(() => repository.getCallLogs()).thenAnswer(
          (_) async => const Failure(ServerFailure('fail')),
        );
        return CallLogCubit(callLogRepository: repository);
      },
      act: (cubit) => cubit.loadCallLogs(),
      expect: () => [
        const CallLogLoading(),
        const CallLogError(message: 'fail'),
      ],
    );

    blocTest<CallLogCubit, CallLogState>(
      'emits [loading, loaded] on successful logCall + reload',
      build: () {
        when(() => repository.logCall(any()))
            .thenAnswer((_) async => Success(_call));
        when(() => repository.getCallLogs())
            .thenAnswer((_) async => Success([_call]));
        return CallLogCubit(callLogRepository: repository);
      },
      act: (cubit) => cubit.logCall(_call),
      expect: () => [
        const CallLogLoading(),
        isA<CallLogLoaded>(),
      ],
    );
  });
}
