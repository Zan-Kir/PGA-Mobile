import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'auth_token';
  static const _keyRefresh = 'refresh_token';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<String?> readToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<void> removeToken() async {
    await _storage.delete(key: _keyToken);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefresh, value: token);
  }

  static Future<String?> readRefreshToken() async {
    return await _storage.read(key: _keyRefresh);
  }

  static Future<void> removeRefreshToken() async {
    await _storage.delete(key: _keyRefresh);
  }
}
