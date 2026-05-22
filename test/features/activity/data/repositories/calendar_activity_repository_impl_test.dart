import 'package:cis_crm/core/error/exceptions.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/activity/data/datasources/activities_data_source.dart';
import 'package:cis_crm/features/activity/data/models/activity_model.dart';
import 'package:cis_crm/features/activity/data/repositories/calendar_activity_repository_impl.dart';
import 'package:cis_crm/features/activity/domain/entities/activity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements ActivitiesDataSource {}

final _activity = ActivityModel(
  id: 'a1',
  activityType: ActivityType.task,
  title: 'T',
  statusId: 's',
  statusName: 'N',
  statusPhase: 'open',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  late _MockDataSource ds;
  late CalendarActivityRepositoryImpl repo;

  /// Stubs ds.getActivities with any params.
  void stubGetActivities(dynamic result) {
    when(() => ds.getActivities(
          type: any(named: 'type'),
          phase: any(named: 'phase'),
          statusId: any(named: 'statusId'),
          assigneeId: any(named: 'assigneeId'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
          startFrom: any(named: 'startFrom'),
          startTo: any(named: 'startTo'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        )).thenAnswer((_) async {
      if (result is List<ActivityModel>) return result;
      throw result as Object;
    });
  }

  setUp(() {
    ds = _MockDataSource();
    repo = CalendarActivityRepositoryImpl(dataSource: ds);
  });

  group('getActivities', () {
    test('returns Success with activities on success', () async {
      stubGetActivities([_activity]);

      final result = await repo.getActivities(from: '2026-05-01', to: '2026-05-31');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, hasLength(1));
      expect(result.dataOrNull!.first.id, 'a1');
    });

    test('returns NetworkFailure on NetworkException', () async {
      stubGetActivities(const NetworkException('offline'));

      final result = await repo.getActivities(from: 'x', to: 'y');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('returns ServerFailure on ServerException', () async {
      stubGetActivities(const ServerException('500', statusCode: 500));

      final result = await repo.getActivities(from: 'x', to: 'y');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(
        (result.failureOrNull! as ServerFailure).statusCode,
        500,
      );
    });

    test('returns UnauthorizedFailure on UnauthorizedException', () async {
      stubGetActivities(const UnauthorizedException('no auth'));

      final result = await repo.getActivities(from: 'x', to: 'y');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });

    test('passes all filter params to data source', () async {
      stubGetActivities(<ActivityModel>[]);

      await repo.getActivities(
        activityType: 'task',
        statusId: 's1',
        phase: 'open',
        assigneeId: 'u1',
        from: '2026-05-01',
        to: '2026-05-31',
        startFrom: '2026-05-01',
        startTo: '2026-05-31',
        page: 2,
        perPage: 50,
      );

      verify(() => ds.getActivities(
            type: ActivityType.task,
            statusId: 's1',
            phase: 'open',
            assigneeId: 'u1',
            from: '2026-05-01',
            to: '2026-05-31',
            startFrom: '2026-05-01',
            startTo: '2026-05-31',
            page: 2,
            perPage: 50,
          )).called(1);
    });
  });
}
