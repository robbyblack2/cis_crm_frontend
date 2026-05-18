import 'package:cis_crm/core/error/failures.dart';
import 'package:cis_crm/core/error/result.dart';
import 'package:cis_crm/features/settings/domain/entities/google_connection.dart';

abstract interface class GoogleRepository {
  Future<Result<String, AppFailure>> getAuthUrl();
  Future<Result<GoogleConnection, AppFailure>> getStatus();
  Future<Result<void, AppFailure>> disconnect();
}
