import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/training_program.dart';

class TrainingService {
  final Dio _dio = DioClient.instance.dio;

  Future<List<TrainingProgram>> getProgramsByMember(int memberId) async {
    final res = await _dio.get(ApiConstants.trainingByMember(memberId));
    final data = res.data;
    final list = data is List ? data : (data is Map ? (data['content'] ?? [data]) : []);
    return (list as List).map((e) => TrainingProgram.fromJson(e)).toList();
  }

  Future<List<TrainingProgram>> getProgramsByCoach(int coachId) async {
    final res = await _dio.get(ApiConstants.trainingByCoach(coachId));
    final data = res.data;
    final list = data is List ? data : (data is Map ? (data['content'] ?? []) : []);
    return (list as List).map((e) => TrainingProgram.fromJson(e)).toList();
  }
}
