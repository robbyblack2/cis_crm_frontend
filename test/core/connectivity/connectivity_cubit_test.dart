import 'dart:async';

import 'package:cis_crm/core/connectivity/connectivity_cubit.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('ConnectivityCubit', () {
    late _MockConnectivity connectivity;
    late StreamController<List<ConnectivityResult>> controller;

    setUp(() {
      connectivity = _MockConnectivity();
      controller = StreamController<List<ConnectivityResult>>();
      when(() => connectivity.onConnectivityChanged)
          .thenAnswer((_) => controller.stream);
    });

    tearDown(() => controller.close());

    test('initial state is online', () {
      final cubit = ConnectivityCubit(connectivity: connectivity);
      expect(cubit.state, ConnectivityStatus.online);
      cubit.close();
    });

    test('emits offline when connectivity is none', () async {
      final cubit = ConnectivityCubit(connectivity: connectivity);
      controller.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, ConnectivityStatus.offline);
      await cubit.close();
    });

    test('emits online when connectivity resumes', () async {
      final cubit = ConnectivityCubit(connectivity: connectivity);
      controller.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);
      controller.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, ConnectivityStatus.online);
      await cubit.close();
    });
  });
}
