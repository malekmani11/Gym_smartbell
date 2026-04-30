import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyToken = 'gym_jwt_token';
  static const _keyUser  = 'gym_user_data';

  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      await p.setString(_keyToken, token);
    } else {
      await _storage.write(key: _keyToken, value: token);
    }
  }

  static Future<String?> getToken() async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      return p.getString(_keyToken);
    }
    return _storage.read(key: _keyToken);
  }

  static Future<void> saveUser(String userJson) async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      await p.setString(_keyUser, userJson);
    } else {
      await _storage.write(key: _keyUser, value: userJson);
    }
  }

  static Future<String?> getUser() async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      return p.getString(_keyUser);
    }
    return _storage.read(key: _keyUser);
  }

  static Future<void> clear() async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      await p.remove(_keyToken);
      await p.remove(_keyUser);
    } else {
      await _storage.deleteAll();
    }
  }
}
