import 'dart:async';

import 'package:cis_crm/core/network/web_socket_event.dart';
import 'package:cis_crm/core/network/web_socket_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Connection status reported by [WebSocketCubit].
enum WebSocketStatus {
  /// Not connected to the server.
  disconnected,

  /// A connection attempt is in progress.
  connecting,

  /// Connected and able to send/receive messages.
  connected,
}

/// Cubit that wraps [WebSocketService] and exposes a reactive
/// [WebSocketStatus].
///
/// Typical usage:
/// ```dart
/// final cubit = WebSocketCubit(webSocketService);
/// cubit.connect();       // moves to connecting -> connected
/// cubit.subscribe('pipeline:abc-123');
/// cubit.disconnect();    // moves to disconnected
/// ```
///
/// Call [connect] when authentication succeeds and [disconnect] when the
/// user logs out.
class WebSocketCubit extends Cubit<WebSocketStatus> {
  WebSocketCubit(this._service) : super(WebSocketStatus.disconnected);

  final WebSocketService _service;
  StreamSubscription<WebSocketEvent>? _eventSub;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Opens the WebSocket connection.
  ///
  /// Emits [WebSocketStatus.connecting] immediately, then
  /// [WebSocketStatus.connected] once the first event arrives, or
  /// falls back to [WebSocketStatus.disconnected] if the service is
  /// unable to connect.
  Future<void> connect() async {
    emit(WebSocketStatus.connecting);

    await _eventSub?.cancel();
    _eventSub = _service.events.listen(
      (_) {
        if (state != WebSocketStatus.connected) {
          emit(WebSocketStatus.connected);
        }
      },
      onDone: () => emit(WebSocketStatus.disconnected),
      onError: (_) => emit(WebSocketStatus.disconnected),
    );

    await _service.connect();

    // If the service connected synchronously (unlikely but possible in
    // tests), reflect the status right away.
    if (_service.isConnected && state != WebSocketStatus.connected) {
      emit(WebSocketStatus.connected);
    }
  }

  /// Closes the WebSocket connection.
  Future<void> disconnect() async {
    await _service.disconnect();
    await _eventSub?.cancel();
    _eventSub = null;
    emit(WebSocketStatus.disconnected);
  }

  /// Subscribes to a server-side channel.
  void subscribe(String channel) => _service.subscribe(channel);

  /// Unsubscribes from a server-side channel.
  void unsubscribe(String channel) => _service.unsubscribe(channel);

  /// Broadcast stream of all incoming [WebSocketEvent]s from the service.
  Stream<WebSocketEvent> get events => _service.events;

  @override
  Future<void> close() async {
    await disconnect();
    return super.close();
  }
}
