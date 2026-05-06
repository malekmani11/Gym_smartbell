import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class JwtInterceptor extends Interceptor {
  /// Called when a 401 is received (e.g. token expired).
  /// Set this callback from main.dart after AuthProvider is created.
  static Future<void> Function()? onUnauthorized;

  static const _jwtSentKey = '_jwt_attached';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      options.extra[_jwtSentKey] = true;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only auto-logout when we actually sent a token that was rejected.
    // If no token was attached, the 401 is expected and the caller handles it.
    final jwtWasSent = err.requestOptions.extra[_jwtSentKey] == true;
    if (err.response?.statusCode == 401 && jwtWasSent) {
      await SecureStorage.clear();
      await onUnauthorized?.call();
    }
    handler.next(err);
  }
}
