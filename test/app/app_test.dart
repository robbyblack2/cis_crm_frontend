import 'package:cis_crm/app/app.dart';
import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/env/flavor_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('App', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await configureDependencies(FlavorConfig.byName('dev'));
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    testWidgets('renders', (tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      expect(find.byType(App), findsOneWidget);
    });
  });
}
