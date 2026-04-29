import 'dart:convert';

import 'api_error.dart';
import 'api_result.dart';
import 'http_transport.dart';

class ApiResponseHandler {
  const ApiResponseHandler();

  ApiResult<T> parseJsonResponse<T>({
    required HttpTransportResponse response,
    required T Function(dynamic json) decode,
  }) {
    final bodyString = utf8.decode(response.bodyBytes, allowMalformed: true);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final trimmed = bodyString.trim();
      dynamic decoded;
      if (trimmed.isNotEmpty) {
        decoded = jsonDecode(trimmed);
      }
      return ApiSuccess(decode(decoded));
    }

    return ApiFailure(
      ApiError.fromHttpResponse(
        statusCode: response.statusCode,
        body: bodyString,
        headers: response.headers,
      ),
    );
  }
}
