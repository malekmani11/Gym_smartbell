import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/device_token_service.dart';
import '../../../core/storage/secure_storage.dart';

import '../models/auth_response.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  AuthStatus _status = AuthStatus.unknown;
  AuthResponse? _user;
  bool _loading = false;
  String? _error;

  AuthStatus get status  => _status;
  AuthResponse? get user => _user;
  bool get loading       => _loading;
  String? get error      => _error;
  bool get isAuth        => _status == AuthStatus.authenticated;
  bool get isAdmin       => _user?.isAdmin  ?? false;
  bool get isCoach       => _user?.isCoach  ?? false;
  bool get isMember      => _user?.isMember ?? false;

  Future<void> tryAutoLogin() async {
    final token   = await SecureStorage.getToken();
    final userStr = await SecureStorage.getUser();
    if (token != null && userStr != null) {
      try {
        _user   = AuthResponse.fromJson(jsonDecode(userStr));
        _status = AuthStatus.authenticated;
      } catch (_) {
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final userResponse = await _service.login(email, password);
      _user = userResponse;
      _error = null;
      await _persist();
      _status = AuthStatus.authenticated;
      _setLoading(false);
      unawaited(DeviceTokenService.registerToken());
      return true;
    } catch (e) {
      _error = DioClient.errorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String firstName, required String lastName,
    required String email, required String password,
    String? phone, String roleName = 'ROLE_MEMBER',
  }) async {
    _setLoading(true);
    try {
      final userResponse = await _service.register(
        firstName: firstName, lastName: lastName,
        email: email, password: password,
        phone: phone, roleName: roleName,
      );
      _user = userResponse;
      await _persist();
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = DioClient.errorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    DeviceTokenService.removeToken();
    try {
      await SecureStorage.clear();
      // Clear all local SharedPreferences data tied to this session
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = prefs.getKeys()
          .where((k) =>
              k.startsWith('smartbell_measurements_') ||
              k == 'gym_pending_training' ||
              k == 'gym_pending_nutrition')
          .toList();
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
    } catch (_) {}
    _user   = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> updateProfile({required String firstName, required String lastName}) async {
    _setLoading(true);
    try {
      final updated = await _service.updateProfile(_user!.id, firstName: firstName, lastName: lastName);
      _user = AuthResponse(
        id:        _user!.id,
        email:     _user!.email,
        firstName: updated['firstName']!,
        lastName:  updated['lastName']!,
        token:     _user!.token,
        role:      _user!.role,
      );
      await _persist();
      _setLoading(false);
      return true;
    } catch (e) {
      _error = DioClient.errorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    try {
      await _service.changePassword(_user!.id, currentPassword, newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = DioClient.errorMessage(e);
      _setLoading(false);
      return false;
    }
  }

  void clearError() { _error = null; notifyListeners(); }

  Future<void> _persist() async {
    await SecureStorage.saveToken(_user!.token);
    await SecureStorage.saveUser(jsonEncode(_user!.toJson()));
  }

  void _setLoading(bool v) {
    _loading = v;
    if (v) _error = null;
    notifyListeners();
  }
}
