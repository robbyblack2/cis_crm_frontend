import 'package:logger/logger.dart';

/// Thin wrapper around the `logger` package.
///
/// The wrapper exists so the rest of the codebase imports `AppLogger`,
/// never `Logger` directly — single point of swap if the logging
/// package is ever changed.
///
/// Per-flavor verbosity is controlled by [Level], read from
/// `FlavorConfig.logLevel`. dev = `Level.trace`; prod = `Level.warning`.
///
/// Logs intentionally never carry state contents or request/response
/// bodies in prod. The bloc observer logs state TYPES only; the Dio
/// logging interceptor strips bodies in prod. See MEMORY's logging
/// + observer entry for the full rationale.
class AppLogger {
  AppLogger({required Level level})
      : _logger = Logger(
          level: level,
          printer: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 5,
            colors: true,
            printEmojis: false,
            dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
          ),
          filter: ProductionFilter(),
        );

  final Logger _logger;

  void trace(String message, [Object? error, StackTrace? stack]) =>
      _logger.t(message, error: error, stackTrace: stack);

  void debug(String message, [Object? error, StackTrace? stack]) =>
      _logger.d(message, error: error, stackTrace: stack);

  void info(String message, [Object? error, StackTrace? stack]) =>
      _logger.i(message, error: error, stackTrace: stack);

  void warn(String message, [Object? error, StackTrace? stack]) =>
      _logger.w(message, error: error, stackTrace: stack);

  void error(String message, [Object? error, StackTrace? stack]) =>
      _logger.e(message, error: error, stackTrace: stack);
}
