import 'dart:convert';
import 'dart:io';

import 'api_response.dart';
import 'api_transport.dart';

ApiTransport createApiTransport() => IoApiTransport();

class IoApiTransport implements ApiTransport {
  final HttpClient _client = HttpClient();

  @override
  Future<ApiResponse> request(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final request = await _client.openUrl(method, uri);
    headers?.forEach(request.headers.set);

    if (body != null) {
      request.add(utf8.encode(body));
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    return ApiResponse(statusCode: response.statusCode, body: responseBody);
  }
}
