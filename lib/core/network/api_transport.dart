import 'api_response.dart';

export 'api_transport_io.dart'
    if (dart.library.html) 'api_transport_web.dart';

abstract class ApiTransport {
  Future<ApiResponse> request(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  });
}
