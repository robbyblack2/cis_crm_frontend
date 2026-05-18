import 'package:cis_crm/features/settings/domain/entities/google_connection.dart';

class GoogleConnectionModel extends GoogleConnection {
  const GoogleConnectionModel({
    required super.connected,
    super.email,
    super.lastSync,
  });

  factory GoogleConnectionModel.fromJson(Map<String, dynamic> json) {
    return GoogleConnectionModel(
      connected: json['connected'] as bool? ?? false,
      email: json['email'] as String?,
      lastSync: json['last_sync'] != null
          ? DateTime.parse(json['last_sync'] as String)
          : null,
    );
  }
}
