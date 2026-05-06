import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';
import '../../../core/storage/secure_storage.dart';
import 'dart:convert';

part 'auth_state.g.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AuthResponse? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthResponse? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

@riverpod
class Auth extends _$Auth {
  final _service = AuthService();

  @override
  AuthState build() => AuthState();

  Future<void> tryAutoLogin() async {
    final token = await SecureStorage.getToken();
    final userStr = await SecureStorage.getUser();
    
    if (token != null && userStr != null) {
      try {
        final user = AuthResponse.fromJson(jsonDecode(userStr));
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } catch (_) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.login(email, password);
      await _persist(user);
      state = state.copyWith(status: AuthStatus.authenticated, user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clear();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _persist(AuthResponse user) async {
    await SecureStorage.saveToken(user.token);
    await SecureStorage.saveUser(jsonEncode(user.toJson()));
  }
}
