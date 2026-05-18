import 'dart:convert';

/// A parsed event received over the WebSocket connection.
class WebSocketEvent {
  const WebSocketEvent({required this.type, required this.data});

  /// Deserialises a raw JSON string into a [WebSocketEvent].
  ///
  /// Expected format:
  /// ```json
  /// { "type": "record.updated", "data": { ... } }
  /// ```
  factory WebSocketEvent.fromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return WebSocketEvent(
      type: map['event'] as String? ?? map['type'] as String? ?? '',
      data: map['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  /// The event type, e.g. `record.created`, `record.moved`.
  final String type;

  /// Arbitrary payload carried by the event.
  final Map<String, dynamic> data;

  @override
  String toString() => 'WebSocketEvent(type: $type, data: $data)';
}
