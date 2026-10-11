import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/socket_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final socketServiceProvider = Provider<SocketService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final service = SocketService(storageService: storage);
  ref.onDispose(() => service.dispose());
  return service;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(
    storageService: storage,
    onSessionExpired: () {
      ref.read(authNotifierProvider.notifier).onSessionExpired();
    },
  );
});

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? token;
  final String? errorMessage;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.user,
    this.token,
    this.errorMessage,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? token,
    String? errorMessage,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final SecureStorageService _storage;
  final SocketService _socketService;

  AuthNotifier(this._apiClient, this._storage, this._socketService) : super(AuthState()) {
    checkCurrentSession();
  }

  Future<void> checkCurrentSession() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(isLoading: false, isAuthenticated: false);
        return;
      }

      final userData = await _storage.getUserData();
      if (userData != null) {
        final parsed = jsonDecode(userData);
        final user = UserModel.fromJson(parsed);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          token: token,
          user: user,
        );
        _socketService.connect();
        // Background verify with /users/me
        _fetchCurrentUser();
        return;
      }

      await _fetchCurrentUser();
    } catch (_) {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final response = await _apiClient.get('/users/me');
      final user = UserModel.fromJson(response is Map<String, dynamic> ? response : {});
      await _storage.saveUserData(
        userId: user.id,
        role: user.role.value,
        rawJson: jsonEncode(user.toJson()),
      );
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );
      _socketService.connect();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout();
      }
    } catch (_) {}
  }

  Future<bool> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {'phone': phone, 'password': password},
      );

      final token = response['token'] as String? ?? response['accessToken'] as String? ?? '';
      final userJson = response['user'] as Map<String, dynamic>? ?? response;
      final user = UserModel.fromJson(userJson);

      await _storage.saveToken(token);
      await _storage.saveUserData(
        userId: user.id,
        role: user.role.value,
        rawJson: jsonEncode(user.toJson()),
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        token: token,
        user: user,
      );

      _socketService.connect();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Sign in failed. Check network.');
      return false;
    }
  }

  Future<bool> register({
    required String displayName,
    required String phone,
    required String password,
    required String requestedRole,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {
          'displayName': displayName,
          'phone': phone,
          'password': password,
          'requestedRole': requestedRole,
        },
      );

      final token = response['token'] as String? ?? response['accessToken'] as String?;
      final userJson = response['user'] as Map<String, dynamic>? ?? response;
      final user = UserModel.fromJson(userJson);

      if (token != null) {
        await _storage.saveToken(token);
        await _storage.saveUserData(
          userId: user.id,
          role: user.role.value,
          rawJson: jsonEncode(user.toJson()),
        );
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: token != null,
        token: token,
        user: user,
      );

      if (token != null) _socketService.connect();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Registration failed. Check network.');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    _socketService.disconnect();
    state = AuthState();
  }

  void onSessionExpired() {
    _socketService.disconnect();
    state = AuthState(
      errorMessage: 'Your session has expired. Please sign in again.',
    );
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  final socketService = ref.watch(socketServiceProvider);
  return AuthNotifier(apiClient, storage, socketService);
});
