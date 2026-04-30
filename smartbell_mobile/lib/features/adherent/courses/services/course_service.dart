import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/course.dart';

class CourseService {
  final Dio _dio = DioClient.instance.dio;

  Future<List<Course>> getCourses({bool activeOnly = true}) async {
    final res = await _dio.get(ApiConstants.courses, queryParameters: {
      'size': 100,
      if (activeOnly) 'active': true,
    });
    final data = res.data;
    final list = data is Map ? (data['content'] ?? []) : (data ?? []);
    return (list as List).map((e) => Course.fromJson(e)).toList();
  }

  Future<void> reserve({required int courseId, required int memberId}) async {
    await _dio.post(ApiConstants.courseReservations, data: {
      'courseId': courseId,
      'memberId': memberId,
    });
  }
}
