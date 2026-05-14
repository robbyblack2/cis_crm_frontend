import 'package:logger/logger.dart';

class AppLogger {
  AppLogger({required Level level})
      : _logger = Logger(
          level: level,
          printer: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 5,
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
