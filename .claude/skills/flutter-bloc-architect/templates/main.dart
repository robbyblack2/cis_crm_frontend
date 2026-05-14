import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/injection.dart';
import 'core/env/flavor_config.dart';
import 'core/logging/app_logger.dart';
import 'core/observability/app_bloc_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'prod');
  final config = FlavorConfig.byName(flavorName);

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory(
            (await getApplicationDocumentsDirectory()).path,
          ),
  );

  await configureDependencies(config);

  Bloc.observer = getIt<AppBlocObserver>();

  final logger = getIt<AppLogger>();
  FlutterError.onError = (details) =>
      logger.error('FlutterError', details.exception, details.stack);
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('PlatformDispatcher', error, stack);
    return true;
  };

  runApp(const App());
}
