// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'api_response.dart';
import 'api_transport.dart';

ApiTransport createApiTransport() => WebApiTransport();

class WebApiTransport implements ApiTransport {
  @override
  Future<ApiResponse> request(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final response = await html.HttpRequest.request(
      uri.toString(),
      method: method,
      requestHeaders: headers,
      sendData: body,
    );

    return ApiResponse(
      statusCode: response.status ?? 0,
      body: response.responseText ?? '',
    );
  }
}
