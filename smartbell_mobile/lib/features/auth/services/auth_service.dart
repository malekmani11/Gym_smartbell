import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/auth_response.dart';

class AuthService {
  final Dio _dio = DioClient.instance.dio;

  Future<AuthResponse> login(String email, String password) async {
    final res = await _dio.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AuthResponse> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String roleName = 'ROLE_MEMBER',
  }) async {
    final res = await _dio.post(ApiConstants.register, data: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'roleName': roleName,
    });
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, String>> updateProfile(int userId, {required String firstName, required String lastName}) async {
    final res = await _dio.put(
      ApiConstants.userById(userId),
      data: {'firstName': firstName, 'lastName': lastName},
    );
    final data = res.data as Map<String, dynamic>;
    return {
      'firstName': (data['firstName'] ?? firstName) as String,
      'lastName':  (data['lastName']  ?? lastName)  as String,
    };
  }

  Future<void> changePassword(int userId, String currentPassword, String newPassword) async {
    await _dio.patch(
      ApiConstants.userPasswordUrl(userId),
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
