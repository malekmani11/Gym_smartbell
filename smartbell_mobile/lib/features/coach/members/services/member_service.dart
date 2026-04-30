import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class CoachMemberService {
  final Dio _dio = DioClient.instance.dio;

  Future<List<Map<String, dynamic>>> getAllMembers() async {
    final res = await _dio.get('/users/by-role', queryParameters: {'role': 'ROLE_MEMBER', 'size': 100});
    final data = res.data;
    final list = data is Map ? (data['content'] ?? []) : (data ?? []);
    return List<Map<String, dynamic>>.from(list);
  }

  Future<Map<String, dynamic>> getMemberByUser(int userId) async {
    final res = await _dio.get(ApiConstants.memberByUser(userId));
    return Map<String, dynamic>.from(res.data);
  }
}
