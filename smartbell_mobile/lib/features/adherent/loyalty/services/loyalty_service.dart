import '../../../core/network/dio_client.dart';

class LoyaltyService {
  final _dio = DioClient.instance.dio;

  Future<Map<String, dynamic>> getBalance(int memberId) async {
    final res = await _dio.get('/loyalty/balance/$memberId');
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getHistory(int memberId, {int page = 0, int size = 20}) async {
    final res = await _dio.get('/loyalty/history/$memberId', queryParameters: {
      'page': page,
      'size': size,
    });
    final data = res.data;
    if (data is Map && data.containsKey('content')) {
      return data['content'] as List<dynamic>;
    }
    return data is List ? data : [];
  }
}
