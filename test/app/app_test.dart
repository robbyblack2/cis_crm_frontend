import 'package:cis_crm/app/app.dart';
import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/core/env/flavor_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockStorage extends Mock implements Storage {}

void main() {
  group('App', () {
    setUp(() async {
      final storage = _MockStorage();
      when(() => storage.read(any())).thenReturn(null);
      when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
      when(() => storage.delete(any())).thenAnswer((_) async {});
      when(storage.clear).thenAnswer((_) async {});
      HydratedBloc.storage = storage;

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
