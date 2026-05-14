import 'package:dio/dio.dart';

import '../logging/app_logger.dart';

/// Hand-rolled Dio request/response logging interceptor.
///
/// No `talker_dio_logger` / `pretty_dio_logger` dependency.
///
/// Verbosity per flavor:
///   - dev/staging: full request/response with header + body redaction.
///   - prod: method + URL + status + duration only. No headers, no bodies.
///
/// Redacted header keys (case-insensitive): `authorization`, `cookie`,
/// `set-cookie`, `x-api-key`, anything ending in `-token`.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({required this.logger, required this.isProd});

  final AppLogger logger;
  final bool isProd;

  static const _redactKeys = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
  };

  static const _maxBodyChars = 2048;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['__startTime'] = DateTime.now();
    if (isProd) {
      logger.info('→ ${options.method} ${options.uri}');
    } else {
      logger.debug(
        '→ ${options.method} ${options.uri}\n'
        'headers: ${_redactHeaders(options.headers)}\n'
        'body: ${_truncate(options.data)}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final duration = _duration(response.requestOptions);
    if (isProd) {
      logger.info(
        '← ${response.statusCode} ${response.requestOptions.uri} (${duration}ms)',
      );
    } else {
      logger.debug(
        '← ${response.statusCode} ${response.requestOptions.uri} (${duration}ms)\n'
        'body: ${_truncate(response.data)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final duration = _duration(err.requestOptions);
    logger.warn(
      '✗ ${err.response?.statusCode ?? '-'} ${err.requestOptions.uri} (${duration}ms): ${err.type}',
    );
    handler.next(err);
  }

  Map<String, dynamic> _redactHeaders(Map<String, dynamic> headers) {
    return {
      for (final entry in headers.entries)
        entry.key:
            _redactKeys.contains(entry.key.toLowerCase()) ||
                    entry.key.toLowerCase().endsWith('-token')
                ? '<redacted>'
                : entry.value,
    };
  }

  String _truncate(Object? body) {
    if (body == null) return 'null';
    final s = body.toString();
    return s.length > _maxBodyChars
        ? '${s.substring(0, _maxBodyChars)}…(truncated ${s.length - _maxBodyChars} chars)'
        : s;
  }

  int _duration(RequestOptions options) {
    final start = options.extra['__startTime'] as DateTime?;
    if (start == null) return 0;
    return DateTime.now().difference(start).inMilliseconds;
  }
}
