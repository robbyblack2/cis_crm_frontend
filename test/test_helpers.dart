// ignore_for_file: avoid_classes_with_only_static_members

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

abstract final class TestHelpers {
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

  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
}
