import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class CoachMemberService {
  final Dio _dio = DioClient.instance.dio;

  /// Retourne les membres inscrits dans les cours de CE coach
  Future<List<Map<String, dynamic>>> getMembersByCoach(int userId) async {
    // 1. Obtenir l'id coach depuis le userId
    final coachRes = await _dio.get(ApiConstants.coachByUser(userId));
    final coachId  = (coachRes.data['id'] ?? 0).toInt();

    // 2. Obtenir les cours de ce coach
    final coursesRes = await _dio.get('${ApiConstants.courses}/coach/$coachId',
        queryParameters: {'size': 100});
    final coursesData = coursesRes.data;
    final coursesList = coursesData is Map
        ? List<Map<String, dynamic>>.from(coursesData['content'] ?? [])
        : List<Map<String, dynamic>>.from(coursesData ?? []);

    // 3. Récupérer les inscrits uniques de tous ces cours
    final Set<int> memberIds = {};
    final List<Map<String, dynamic>> members = [];

    for (final course in coursesList) {
      final courseId = (course['id'] ?? 0).toInt();
      if (courseId == 0) continue;
      try {
        final regRes = await _dio.get('${ApiConstants.courses}/$courseId/reservations');
        final regs   = List<Map<String, dynamic>>.from(regRes.data ?? []);
        for (final reg in regs) {
          final uid = (reg['userId'] ?? reg['memberId'] ?? 0).toInt();
          if (uid > 0 && !memberIds.contains(uid)) {
            memberIds.add(uid);
            members.add({
              'id':        uid,
              'firstName': reg['firstName'] ?? reg['memberName']?.toString().split(' ').first ?? '',
              'lastName':  reg['lastName']  ?? (reg['memberName']?.toString().split(' ').length ?? 0) > 1
                  ? reg['memberName'].toString().split(' ').last : '',
              'email':     reg['email'] ?? '',
              'profileImageUrl': reg['profileImageUrl'],
            });
          }
        }
      } catch (_) {}
    }
    return members;
  }

  // Gardé pour compatibilité
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
