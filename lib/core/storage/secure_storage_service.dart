import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _tokenKey = 'sahaay_auth_token';
  static const _userRoleKey = 'sahaay_user_role';
  static const _userIdKey = 'sahaay_user_id';
  static const _userDataKey = 'sahaay_user_data';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveUserData({
    required String userId,
    required String role,
    String? rawJson,
  }) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _userRoleKey, value: role);
    if (rawJson != null) {
      await _storage.write(key: _userDataKey, value: rawJson);
    }
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: _userDataKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
