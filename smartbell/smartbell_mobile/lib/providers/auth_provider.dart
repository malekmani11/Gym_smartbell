import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/token_storage.dart';
import '../models/auth_models.dart';

class AuthProvider extends ChangeNotifier {
  AuthResponse? _user;
  bool _loading = false;
  String? _error;

  AuthResponse? get user    => _user;
  bool          get loading => _loading;
  String?       get error   => _error;
  bool          get isAuth  => _user != null;

  Future<void> tryAutoLogin() async {
    final token   = await TokenStorage.getToken();
    final userStr = await TokenStorage.getUser();
    if (token != null && userStr != null) {
      _user = AuthResponse.fromJson(jsonDecode(userStr));
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiClient().dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      _user = AuthResponse.fromJson(res.data);
      await TokenStorage.saveToken(_user!.token);
      await TokenStorage.saveUser(jsonEncode(_user!.toJson()));
      _loading = false; notifyListeners();
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      _error = (data is Map ? data['message'] : null) ?? 'Email ou mot de passe incorrect';
      _loading = false; notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String firstName, required String lastName,
    required String email,     required String password,
    String? phone,             String roleName = 'ROLE_MEMBER',
  }) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiClient().dio.post(ApiConstants.register, data: {
        'firstName': firstName, 'lastName': lastName,
        'email': email,         'password': password,
        if (phone != null) 'phone': phone,
        'roleName': roleName,
      });
      _user = AuthResponse.fromJson(res.data);
      await TokenStorage.saveToken(_user!.token);
      await TokenStorage.saveUser(jsonEncode(_user!.toJson()));
      _loading = false; notifyListeners();
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      _error = (data is Map ? data['message'] : null) ?? 'Erreur lors de l\'inscription';
      _loading = false; notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    _user = null;
    notifyListeners();
  }
}
