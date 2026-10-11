import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  UserModel? _currentUser;
  String? _token;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null;

  static const String _keyToken = 'sahaay_auth_token';
  static const String _keyUser = 'sahaay_user_profile';

  // Preset demo accounts matching backend/src/scripts/seed.ts
  static final List<Map<String, dynamic>> demoAccounts = [
    {
      'name': 'Kamla Devi (Amma)',
      'phone': '+919876543210',
      'password': 'password123',
      'role': UserRole.elderlyUser,
      'description': 'Elderly resident in Koramangala, Bengaluru (SOS Creator)',
    },
    {
      'name': 'Rahul Sharma',
      'phone': '+919876543211',
      'password': 'password123',
      'role': UserRole.volunteer,
      'description': 'Verified community volunteer (~350m away)',
    },
    {
      'name': 'Amit Verma',
      'phone': '+919876543213',
      'password': 'password123',
      'role': UserRole.volunteer,
      'description': 'Verified secondary responder (Race demo)',
    },
    {
      'name': 'Admin User',
      'phone': '+919876543200',
      'password': 'password123',
      'role': UserRole.admin,
      'description': 'Network administrator & verifier',
    },
  ];

  /// Load session from SharedPreferences on device
  Future<UserModel?> loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_keyToken);
      final savedUserJson = prefs.getString(_keyUser);

      if (savedToken != null && savedUserJson != null) {
        _token = savedToken;
        apiClient.setAuthToken(savedToken);
        final map = jsonDecode(savedUserJson) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(map);
        return _currentUser;
      }
    } catch (e) {
      // Ignore reading error
    }
    return null;
  }

  /// Save session to SharedPreferences on device
  Future<void> _saveSession(UserModel user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    } catch (e) {
      // Ignore writing error
    }
  }

  /// Clear session from device
  Future<void> clearSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
    } catch (_) {}
    _currentUser = null;
    _token = null;
    apiClient.setAuthToken(null);
  }

  Future<UserModel> login({
    required String phone,
    required String password,
    UserRole? preferredRole,
    bool remember = true,
  }) async {
    try {
      final res = await apiClient.post(
        '/auth/login',
        body: {'phone': phone, 'password': password},
      );
      _token = res['token'];
      apiClient.setAuthToken(_token);
      _currentUser = UserModel.fromJson(res['user']);
      if (remember) {
        await _saveSession(_currentUser!, _token!);
      }
      return _currentUser!;
    } catch (e) {
      // Offline fallback: check if it matches a preset or create based on preferred role
      final cleanPhone = phone.trim();
      final demo = demoAccounts.firstWhere(
        (a) => a['phone'] == cleanPhone,
        orElse: () => {
          'name': preferredRole == UserRole.volunteer
              ? 'Rahul Sharma'
              : 'Kamla Devi (Amma)',
          'phone': cleanPhone,
          'role': preferredRole ?? UserRole.elderlyUser,
        },
      );

      _token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      apiClient.setAuthToken(_token);
      _currentUser = UserModel(
        id: 'usr_${cleanPhone.replaceAll('+', '')}',
        displayName: demo['name'],
        phone: cleanPhone,
        role: preferredRole ?? demo['role'],
        createdAt: DateTime.now(),
      );
      if (remember) {
        await _saveSession(_currentUser!, _token!);
      }
      return _currentUser!;
    }
  }

  Future<void> logout() async {
    await clearSavedSession();
  }

  void switchPersona(UserRole role) {
    final demo = demoAccounts.firstWhere(
      (a) => a['role'] == role,
      orElse: () => demoAccounts.first,
    );

    _currentUser = UserModel(
      id: 'usr_${(demo['phone'] as String).replaceAll('+', '')}',
      displayName: demo['name'],
      phone: demo['phone'],
      role: demo['role'],
      createdAt: DateTime.now(),
    );
    _token = 'mock_jwt_token_switch';
    apiClient.setAuthToken(_token);
    _saveSession(_currentUser!, _token!);
  }
}

final authService = AuthService();
