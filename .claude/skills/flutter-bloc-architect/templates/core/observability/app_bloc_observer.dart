import 'package:flutter_bloc/flutter_bloc.dart';

import '../logging/app_logger.dart';

/// Minimal bloc observer.
///
/// Logs:
///   - state TYPE on `onChange` (e.g., `'AuthBloc: AuthInitial → AuthAuthenticated'`).
///     Never state contents — keeps PII out of logs by default.
///   - errors via `AppLogger.error`.
///
/// Does NOT override `onEvent`, `onTransition`, `onCreate`, `onClose`.
/// The default behavior is enough; overriding adds noise without signal.
///
/// When Sentry is opted in (FlavorConfig.sentryDsn != null), an inline
/// `if (Sentry.isEnabled) ...` is added to `onError` and `onChange`
/// in this file. The skill does NOT ship an `ErrorReporter` interface;
/// the conditional is two lines of code, the indirection isn't worth it.
class AppBlocObserver extends BlocObserver {
  AppBlocObserver(this._logger);

  final AppLogger _logger;

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    _logger.info(
      '${bloc.runtimeType}: ${change.nextState.runtimeType}',
    );
    // Sentry breadcrumb (state TYPE only — never contents):
    // if (Sentry.isEnabled) {
    //   Sentry.addBreadcrumb(Breadcrumb(
    //     category: 'bloc',
    //     message: '${bloc.runtimeType}: ${change.nextState.runtimeType}',
    //     level: SentryLevel.info,
    //   ));
    // }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _logger.error('${bloc.runtimeType} error', error, stackTrace);
    // if (Sentry.isEnabled) {
    //   Sentry.captureException(error, stackTrace: stackTrace);
    // }
    super.onError(bloc, error, stackTrace);
  }
}
