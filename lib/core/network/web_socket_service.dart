import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cis_crm/core/network/token_storage.dart';
import 'package:cis_crm/core/network/web_socket_event.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Service that manages a single WebSocket connection to the CRM API.
///
/// Features:
/// * Automatic reconnection with exponential back-off (1 s -> 30 s cap).
/// * Channel subscribe / unsubscribe helpers.
/// * A broadcast [events] stream for parsed [WebSocketEvent]s.
class WebSocketService {
  WebSocketService({
    required String baseUrl,
    required TokenStorage tokenStorage,
  })  : _baseUrl = baseUrl,
        _tokenStorage = tokenStorage;

  final String _baseUrl;
  final TokenStorage _tokenStorage;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  final _controller = StreamController<WebSocketEvent>.broadcast();
  final _activeChannels = <String>{};

  bool _intentionalDisconnect = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  /// Maximum back-off duration in seconds.
  static const int maxBackoffSeconds = 30;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Whether the underlying WebSocket is currently open.
  bool get isConnected => _channel != null;

  /// Broadcast stream of all incoming [WebSocketEvent]s.
  Stream<WebSocketEvent> get events => _controller.stream;

  /// Builds the WebSocket URI for the given [token].
  ///
  /// Replaces `http(s)://` with `ws(s)://` and appends the path + query.
  Uri buildUri(String token) {
    final wsScheme = _baseUrl.startsWith('https') ? 'wss' : 'ws';
    final authority =
        _baseUrl.replaceFirst('https://', '').replaceFirst('http://', '');
    return Uri.parse('$wsScheme://$authority/api/ws?token=$token');
  }

  /// Opens a WebSocket connection using the stored access token.
  ///
  /// If a connection already exists it is closed first.
  Future<void> connect() async {
    _intentionalDisconnect = false;
    _reconnectAttempts = 0;

    final token = await _tokenStorage.readAccess();
    if (token == null || token.isEmpty) return;

    await _openConnection(token);
  }

  /// Gracefully closes the connection.  No automatic reconnect will occur.
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _closeConnection();
  }

  /// Subscribes to a server-side channel (e.g. `pipeline:abc-123`).
  void subscribe(String channel) {
    _activeChannels.add(channel);
    _send({'action': 'subscribe', 'channel': channel});
  }

  /// Unsubscribes from a previously subscribed channel.
  void unsubscribe(String channel) {
    _activeChannels.remove(channel);
    _send({'action': 'unsubscribe', 'channel': channel});
  }

  /// Releases all resources.  Call when the service is no longer needed.
  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _openConnection(String token) async {
    await _closeConnection();

    try {
      final uri = buildUri(token);
      _channel = WebSocketChannel.connect(uri);

      // Wait for the connection to be ready (throws on failure).
      await _channel!.ready;

      _subscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );

      _reconnectAttempts = 0;

      // Re-subscribe to channels that were active before a reconnect.
      for (final channel in _activeChannels) {
        _send({'action': 'subscribe', 'channel': channel});
      }
    } catch (_) {
      // Connection failed — schedule a reconnect silently.
      _channel = null;
      if (!_intentionalDisconnect) {
        _scheduleReconnect();
      }
    }
  }

  Future<void> _closeConnection() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  void _send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    try {
      _controller.add(WebSocketEvent.fromJson(raw));
    } catch (_) {
      // Silently ignore malformed messages.
    }
  }

  void _onError(Object error, StackTrace stackTrace) {
    // The stream will call onDone after an error, so reconnect logic
    // is handled there.
  }

  void _onDone() {
    _channel = null;
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  /// Calculates back-off: min(2^attempts, [maxBackoffSeconds]).
  int backoffSeconds(int attempt) =>
      min(pow(2, attempt).toInt(), maxBackoffSeconds);

  void _scheduleReconnect() {
    final delay = backoffSeconds(_reconnectAttempts);
    _reconnectAttempts++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () async {
      final token = await _tokenStorage.readAccess();
      if (token != null && token.isNotEmpty) {
        await _openConnection(token);
      } else {
        // No valid token — stop retrying.
        _intentionalDisconnect = true;
      }
    });
  }
}
