import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../models/program_generation_response.dart';

class ProgramService {
  final Dio _dio = DioClient.instance.dio;

  Future<ProgramGenerationResponse> generateProgram({
    required int    memberId,
    required double poids,
    required double taille,
    required int    age,
    required String sexe,
    required String objectif,
    required String niveau,
    required int    seances,
  }) async {
    try {
      final response = await _dio.post(
        '/ai/generate-program/$memberId',
        data: {
          'poids'   : poids,
          'taille'  : taille,
          'age'     : age,
          'sexe'    : sexe,
          'objectif': objectif,
          'niveau'  : niveau,
          'seances' : seances,
        },
        options: Options(
          sendTimeout   : const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      return ProgramGenerationResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = (e.response?.data is Map)
          ? e.response!.data['message'] as String? ?? 'Erreur API'
          : 'Impossible de générer le programme. Vérifiez votre connexion.';
      throw Exception(message);
    }
  }
}
