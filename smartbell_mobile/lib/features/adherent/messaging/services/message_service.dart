import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/message.dart';

class MessageService {
  final Dio _dio = DioClient.instance.dio;

  Future<List<Message>> getConversation(int userId1, int userId2) async {
    final res = await _dio.get(ApiConstants.conversation(userId1, userId2));
    final data = res.data;
    final list = data is List ? data : (data is Map ? (data['content'] ?? []) : []);
    return (list as List).map((e) => Message.fromJson(e)).toList();
  }

  Future<Message> sendMessage({
    required int senderId,
    required int receiverId,
    required String content,
  }) async {
    final res = await _dio.post(ApiConstants.sendMessage(senderId), data: {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
    });
    return Message.fromJson(res.data as Map<String, dynamic>);
  }
}
