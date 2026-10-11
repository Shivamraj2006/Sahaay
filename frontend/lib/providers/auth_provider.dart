import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null;
  String? get token => authService.token;
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
      if (authService.token != null) {
        socketService.connect(authService.token!);
      }
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> register({
    required String displayName,
    required String phone,
    required String password,
    required UserRole role,
    bool remember = true,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await authService.register(
        displayName: displayName,
        phone: phone,
        password: password,
        role: role,
        remember: remember,
      );
      if (authService.token != null) {
        socketService.connect(authService.token!);
      }
    } finally {
      _isLoading = false;
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
      if (authService.token != null) {
        socketService.connect(authService.token!);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> guestLogin({String? displayName}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await authService.guestLogin(displayName: displayName);
      if (authService.token != null) {
        socketService.connect(authService.token!);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await authService.updateProfile(displayName);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void switchRole(UserRole role) {
    authService.switchPersona(role);
    _user = authService.currentUser;
    if (authService.token != null) {
      socketService.connect(authService.token!);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      socketService.disconnect();
      await authService.logout();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
