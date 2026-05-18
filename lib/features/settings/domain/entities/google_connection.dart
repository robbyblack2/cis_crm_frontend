import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class GoogleConnection extends Equatable {
  const GoogleConnection({
    required this.connected,
    this.email,
    this.lastSync,
  });

  final bool connected;
  final String? email;
  final DateTime? lastSync;

  static const disconnected = GoogleConnection(connected: false);

  @override
  List<Object?> get props => [connected, email, lastSync];
}
