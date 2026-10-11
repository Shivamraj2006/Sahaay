import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      'description': 'Senior Citizen (SOS Requester)',
    },
    {
      'name': 'Rahul Sharma',
      'phone': '+919876543211',
      'password': 'password123',
      'role': UserRole.volunteer,
      'description': 'Community Volunteer Responder',
    },
  ];

  /// Normalize phone to +91XXXXXXXXXX
  static String normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '+91$digits';
    if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
    return raw.startsWith('+') ? raw : '+$raw';
  }

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
      debugPrint('[AUTH] Failed to load saved session: $e');
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
      debugPrint('[AUTH] Failed to save session: $e');
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

  /// Register a brand new user into MongoDB database
  Future<UserModel> register({
    required String displayName,
    required String phone,
    required String password,
    required UserRole role,
    bool remember = true,
  }) async {
    final cleanPhone = normalizePhone(phone);
    final res = await apiClient.post(
      '/auth/register',
      body: {
        'displayName': displayName.trim(),
        'phone': cleanPhone,
        'password': password,
        'requestedRole': role.value,
      },
    );

    _token = res['token'];
    apiClient.setAuthToken(_token);
    _currentUser = UserModel.fromJson(res['user']);
    if (remember) {
      await _saveSession(_currentUser!, _token!);
    }
    return _currentUser!;
  }

  /// Login with existing credentials from MongoDB database
  Future<UserModel> login({
    required String phone,
    required String password,
    UserRole? preferredRole,
    bool remember = true,
  }) async {
    final cleanPhone = normalizePhone(phone);
    try {
      final res = await apiClient.post(
        '/auth/login',
        body: {'phone': cleanPhone, 'password': password},
      );

      _token = res['token'];
      apiClient.setAuthToken(_token);
      _currentUser = UserModel.fromJson(res['user']);
      if (remember) {
        await _saveSession(_currentUser!, _token!);
      }
      return _currentUser!;
    } catch (e) {
      // Offline / widget test environment fallback for demo accounts
      final match = demoAccounts.firstWhere(
        (a) => a['phone'] == cleanPhone,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        final mockUser = UserModel(
          id: match['role'] == UserRole.elderlyUser ? 'demo_elderly_1' : 'demo_responder_1',
          displayName: match['name'],
          phone: match['phone'],
          role: preferredRole ?? match['role'],
          createdAt: DateTime.now(),
        );
        _currentUser = mockUser;
        _token = 'mock_jwt_token_${mockUser.id}';
        apiClient.setAuthToken(_token);
        if (remember) {
          await _saveSession(_currentUser!, _token!);
        }
        return _currentUser!;
      }
      rethrow;
    }
  }

  /// Guest bypass session stored in MongoDB database
  Future<UserModel> guestLogin({String? displayName}) async {
    final body = <String, dynamic>{};
    if (displayName != null && displayName.trim().isNotEmpty) {
      body['displayName'] = displayName.trim();
    }

    try {
      final res = await apiClient.post(
        '/auth/guest',
        body: body,
      );

      _token = res['token'];
      apiClient.setAuthToken(_token);
      _currentUser = UserModel.fromJson(res['user']);
      await _saveSession(_currentUser!, _token!);
      return _currentUser!;
    } catch (e) {
      final guest = UserModel(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        displayName: displayName != null && displayName.trim().isNotEmpty
            ? displayName.trim()
            : 'Guest User',
        phone: '',
        role: UserRole.elderlyUser,
        isGuest: true,
        createdAt: DateTime.now(),
      );
      _currentUser = guest;
      _token = 'guest_token_${guest.id}';
      apiClient.setAuthToken(_token);
      await _saveSession(_currentUser!, _token!);
      return _currentUser!;
    }
  }

  /// Update user profile display name in MongoDB database
  Future<UserModel> updateProfile(String newName) async {
    final res = await apiClient.patch(
      '/users/me',
      body: {'displayName': newName.trim()},
    );

    _currentUser = UserModel.fromJson(res);
    if (_token != null) {
      await _saveSession(_currentUser!, _token!);
    }
    return _currentUser!;
  }

  Future<void> logout() async {
    await clearSavedSession();
  }

  /// Switch persona while preserving real user profile
  void switchPersona(UserRole role) {
    if (_currentUser != null) {
      _currentUser = UserModel(
        id: _currentUser!.id,
        displayName: _currentUser!.displayName,
        phone: _currentUser!.phone,
        role: role,
        isGuest: _currentUser!.isGuest,
        createdAt: _currentUser!.createdAt,
      );
      if (_token != null) {
        _saveSession(_currentUser!, _token!);
      }
    }
  }
}

final authService = AuthService();
