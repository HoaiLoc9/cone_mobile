// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
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
  }) {
    final completer = Completer<ApiResponse>();
    final xhr = html.HttpRequest();

    xhr.open(method, uri.toString(), async: true);

    if (headers != null) {
      headers.forEach((key, value) {
        xhr.setRequestHeader(key, value);
      });
    }

    xhr.onLoad.listen((_) {
      if (!completer.isCompleted) {
        completer.complete(
          ApiResponse(
            statusCode: xhr.status ?? 0,
            body: xhr.responseText ?? '',
          ),
        );
      }
    });

    xhr.onError.listen((_) {
      if (!completer.isCompleted) {
        final status = xhr.status ?? 0;
        if (status > 0) {
          completer.complete(
            ApiResponse(
              statusCode: status,
              body: xhr.responseText ?? '',
            ),
          );
        } else {
          completer.completeError(
            Exception(
              'Không thể kết nối máy chủ (${uri.host}). Vui lòng kiểm tra kết nối mạng hoặc thử lại sau.',
            ),
          );
        }
      }
    });

    xhr.onAbort.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Yêu cầu tới máy chủ đã bị hủy.'));
      }
    });

    try {
      xhr.send(body);
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    return completer.future;
  }
}
