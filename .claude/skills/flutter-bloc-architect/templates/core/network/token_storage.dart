import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The shared abstraction for reading and writing the access + refresh
/// token pair.
///
/// Both [AuthInterceptor] (in `core/network/`) and `AuthRepositoryImpl`
/// (in `features/auth/data/repositories/`) depend on this class.
/// The interceptor never imports a feature; the repository never reads
/// secure storage directly. This is the seam.
///
/// Single account per app — there is exactly one access/refresh pair in
/// storage at any time. Multi-account is an explicit per-project
/// deviation that requires reshaping this class.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<String?> readAccess() => _storage.read(key: _accessKey);

  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  Future<void> write({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
