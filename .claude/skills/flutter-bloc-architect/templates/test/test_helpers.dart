// ignore_for_file: avoid_classes_with_only_static_members

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared helpers for widget + bloc tests.
abstract final class TestHelpers {
  /// Wraps [child] with a `MaterialApp` and the bloc providers needed for
  /// the test. Use in widget tests so `Theme.of(context)` and `Navigator`
  /// are available.
  static Widget wrap({
    required Widget child,
    List<BlocProvider> providers = const [],
  }) {
    Widget app = MaterialApp(home: Scaffold(body: child));
    if (providers.isNotEmpty) {
      app = MultiBlocProvider(providers: providers, child: app);
    }
    return app;
  }

  /// Pumps until all microtasks settle. Use after dispatching events that
  /// trigger async chains.
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
}
