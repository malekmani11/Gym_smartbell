import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/nutrition_plan.dart';

class NutritionService {
  final Dio _dio = DioClient.instance.dio;

  Future<List<NutritionPlan>> getPlansByMember(int memberId) async {
    final res = await _dio.get(ApiConstants.nutritionByMember(memberId));
    final data = res.data;
    final list = data is List ? data : (data is Map ? (data['content'] ?? []) : []);
    return (list as List).map((e) => NutritionPlan.fromJson(e)).toList();
  }
}
