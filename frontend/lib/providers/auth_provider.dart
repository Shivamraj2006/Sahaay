import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null;
  bool get isElderly => _user?.isElderly ?? true;
  bool get isResponder => _user?.isResponder ?? false;

  AuthProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await authService.loadSavedSession();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> login({
    required String phone,
    required String password,
    UserRole? preferredRole,
    bool remember = true,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await authService.login(
        phone: phone,
        password: password,
        preferredRole: preferredRole,
        remember: remember,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void switchRole(UserRole role) {
    authService.switchPersona(role);
    _user = authService.currentUser;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await authService.logout();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
