import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/dio_client.dart';

class DeviceTokenService {
  static final _dio = DioClient.instance.dio;

  static bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> registerToken() async {
    if (!_isMobile) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await _dio.post('/devices/token', data: {
        'token': token,
        'platform': 'ANDROID',
      });
    } catch (e) {
      // Non bloquant — l'app fonctionne sans FCM
    }
  }

  static Future<void> removeToken() async {
    if (!_isMobile) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await _dio.delete('/devices/token', data: {'token': token});
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }
}
