import 'package:basketball_academy/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  final FlutterSecureStorage _storage;

  const TokenManager(this._storage);

  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      debugPrint('[TOKEN] getToken() → ${token != null ? "FOUND(${token.length}chars)" : "NULL"}');
      return token;
    } catch (e) {
      debugPrint('[TOKEN] getToken() → EXCEPTION: $e');
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      debugPrint('[TOKEN] saveToken() → writing to secure storage...');
      await _storage.write(key: AppConstants.tokenKey, value: token);
      debugPrint('[TOKEN] saveToken() → DONE ✓');
    } catch (e) {
      debugPrint('[TOKEN] saveToken() → EXCEPTION: $e');
      rethrow;
    }
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  Future<void> clearToken() async {
    debugPrint('[TOKEN] clearToken() → deleting tokens');
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    debugPrint('[TOKEN] clearToken() → DONE ✓');
  }

  Future<bool> hasToken() async {
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      final result = token != null && token.isNotEmpty;
      debugPrint('[TOKEN] hasToken() → $result');
      return result;
    } catch (e) {
      debugPrint('[TOKEN] hasToken() → EXCEPTION: $e → returning false');
      return false;
    }
  }
}
