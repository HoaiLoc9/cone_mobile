import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class ChatbotMessage {
  const ChatbotMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class ChatbotService {
  ChatbotService({required String token, ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient() {
    _apiClient.setToken(token);
  }

  final ApiClient _apiClient;

  Future<String> ask(String question) async {
    final data = await _apiClient.post(
      '/mobile/chatbot/ask',
      body: {'question': question},
    );
    if (data['success'] != true) {
      throw ApiException(
        data['message']?.toString() ?? 'Chatbot chưa trả lời được.',
      );
    }
    final payload = data['data'] as Map<String, dynamic>? ?? {};
    return payload['answer']?.toString() ?? '';
  }
}
