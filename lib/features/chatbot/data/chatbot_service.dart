import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/locale_service.dart';

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
    final lang = LocaleService.instance.localeCode;
    final data = await _apiClient.post(
      '/mobile/chatbot/ask',
      body: {
        'question': question,
        'lang': lang,
      },
    );
    if (data['success'] != true) {
      throw ApiException(
        data['message']?.toString() ??
            tr('Chatbot chưa trả lời được.', 'Chatbot could not respond.'),
      );
    }
    final payload = data['data'] as Map<String, dynamic>? ?? {};
    return payload['answer']?.toString() ?? '';
  }
}
