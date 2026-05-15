import 'package:bloc_test/bloc_test.dart';
import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/products/domain/entities/subscription.dart';
import 'package:cis_crm/features/products/domain/entities/subscription_status.dart';
import 'package:cis_crm/features/products/domain/repositories/subscription_repository.dart';
import 'package:cis_crm/features/products/presentation/bloc/subscriptions_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

void main() {
  late MockSubscriptionRepository mockRepository;

  setUp(() {
    mockRepository = MockSubscriptionRepository();
  });

  final tSubscription = Subscription(
    id: 's1',
    companyId: 'c1',
    systemId: 'sys1',
    productType: 'monitoring',
    status: SubscriptionStatus.active,
    tags: const ['premium'],
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  group('SubscriptionsBloc', () {
    blocTest<SubscriptionsBloc, SubscriptionsState>(
      'emits [Loading, Loaded] when SubscriptionsLoadRequested succeeds',
      build: () {
        when(() => mockRepository.getSubscriptions())
            .thenAnswer((_) async => Success([tSubscription]));
        return SubscriptionsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SubscriptionsLoadRequested()),
      expect: () => [
        const SubscriptionsLoading(),
        SubscriptionsLoaded(subscriptions: [tSubscription]),
      ],
    );

    blocTest<SubscriptionsBloc, SubscriptionsState>(
      'emits [Loading, Error] when SubscriptionsLoadRequested fails',
      build: () {
        when(() => mockRepository.getSubscriptions()).thenAnswer(
          (_) async => const Failure(ServerFailure('Server error')),
        );
        return SubscriptionsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SubscriptionsLoadRequested()),
      expect: () => [
        const SubscriptionsLoading(),
        const SubscriptionsError(message: 'Server error'),
      ],
    );

    blocTest<SubscriptionsBloc, SubscriptionsState>(
      'emits [Loading, Error] when SubscriptionCreateRequested fails',
      build: () {
        when(
          () => mockRepository.createSubscription(
            companyId: any(named: 'companyId'),
            systemId: any(named: 'systemId'),
            productType: any(named: 'productType'),
            tags: any(named: 'tags'),
          ),
        ).thenAnswer(
          (_) async => const Failure(ServerFailure('Create failed')),
        );
        return SubscriptionsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(
        const SubscriptionCreateRequested(
          companyId: 'c1',
          systemId: 'sys1',
          productType: 'monitoring',
        ),
      ),
      expect: () => [
        const SubscriptionsLoading(),
        const SubscriptionsError(message: 'Create failed'),
      ],
    );

    blocTest<SubscriptionsBloc, SubscriptionsState>(
      'emits [Loading, Loaded] when SubscriptionCreateRequested '
      'succeeds and triggers reload',
      build: () {
        when(
          () => mockRepository.createSubscription(
            companyId: any(named: 'companyId'),
            systemId: any(named: 'systemId'),
            productType: any(named: 'productType'),
            tags: any(named: 'tags'),
          ),
        ).thenAnswer((_) async => Success(tSubscription));
        when(() => mockRepository.getSubscriptions())
            .thenAnswer((_) async => Success([tSubscription]));
        return SubscriptionsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(
        const SubscriptionCreateRequested(
          companyId: 'c1',
          systemId: 'sys1',
          productType: 'monitoring',
        ),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const SubscriptionsLoading(),
        SubscriptionsLoaded(subscriptions: [tSubscription]),
      ],
    );
  });
}
