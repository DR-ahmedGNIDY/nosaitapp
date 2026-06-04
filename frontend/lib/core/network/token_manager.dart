import 'package:basketball_academy/core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  final FlutterSecureStorage _storage;

  const TokenManager(this._storage);

  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
