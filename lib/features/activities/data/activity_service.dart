import '../../../core/network/api_client.dart';
import 'activity_model.dart';

class ActivityService {
  ActivityService({required String token, ApiClient? apiClient})
    : token = token,
      _apiClient = apiClient ?? ApiClient() {
    _apiClient.setToken(token);
  }

  final String token;
  final ApiClient _apiClient;

  Future<ActivityPage> fetchActivities({
    int page = 1,
    String keyword = '',
    String status = '',
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'per_page': '12',
      if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      if (status.isNotEmpty) 'status': status,
    };
    final uri = Uri(path: '/mobile/activities', queryParameters: query);
    final data = await _apiClient.get(uri.toString());
    return ActivityPage.fromJson(data);
  }

  Future<List<ActivityItem>> fetchRegisteredActivities() async {
    final registered = <ActivityItem>[];
    var page = 1;
    var lastPage = 1;

    do {
      final result = await fetchActivities(page: page);
      registered.addAll(result.items.where((item) => item.isRegistered));
      lastPage = result.lastPage;
      page++;
    } while (page <= lastPage);

    return registered;
  }

  Future<ActivityItem> fetchActivity(String id) async {
    final data = await _apiClient.get('/mobile/activities/$id');
    return ActivityItem.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<ActivityItem> register(String id) async {
    final data = await _apiClient.post('/mobile/activities/$id/register');
    return ActivityItem.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<ActivityItem> cancel(String id) async {
    final data = await _apiClient.post('/mobile/activities/$id/cancel');
    return ActivityItem.fromJson(data['data'] as Map<String, dynamic>);
  }
}
