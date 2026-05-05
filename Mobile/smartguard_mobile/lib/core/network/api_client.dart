import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import 'api_error.dart';
import 'api_response_handler.dart';
import 'api_result.dart';
import 'http_transport.dart';
import 'io_http_transport.dart';

class ApiClient {
  ApiClient({
    String? baseUrl,
    HttpTransport? transport,
    this.timeout = const Duration(seconds: 30),
    Map<String, String> defaultHeaders = const {},
  }) : _baseUri = Uri.parse(_normalizeBaseUrl(baseUrl ?? AppConfig.apiBaseUrl)),
       _transport = transport ?? IoHttpTransport(),
       _defaultHeaders = Map.unmodifiable({
         'accept': 'application/json',
         ...defaultHeaders,
       });

  final Uri _baseUri;
  final HttpTransport _transport;
  final Duration timeout;
  final Map<String, String> _defaultHeaders;

  Future<ApiResult<T>> requestJson<T>({
    required String method,
    required String path,
    required T Function(dynamic json) decode,
    Map<String, String> headers = const {},
    Map<String, dynamic>? queryParameters,
    Object? jsonBody,
  }) async {
    final uri = _resolve(path, queryParameters);
    final mergedHeaders = <String, String>{..._defaultHeaders, ...headers};

    List<int>? bodyBytes;
    if (jsonBody != null) {
      mergedHeaders.putIfAbsent(
        'content-type',
        () => 'application/json; charset=utf-8',
      );
      bodyBytes = utf8.encode(jsonEncode(jsonBody));
    }

    try {
      final response = await _transport.send(
        HttpTransportRequest(
          method: method,
          uri: uri,
          headers: mergedHeaders,
          timeout: timeout,
          bodyBytes: bodyBytes,
        ),
      );

      return const ApiResponseHandler().parseJsonResponse(
        response: response,
        decode: decode,
      );
    } on FormatException catch (e) {
      return ApiFailure(ApiError.invalidResponse(e));
    } on TimeoutException catch (e) {
      return ApiFailure(ApiError.timeout(e));
    } on SocketException catch (e) {
      return ApiFailure(ApiError.network(e));
    } catch (e) {
      return ApiFailure(ApiError.network(e));
    }
  }

  Uri _resolve(String path, Map<String, dynamic>? queryParameters) {
    final resolved = _baseUri.resolve(
      path.startsWith('/') ? path.substring(1) : path,
    );
    if (queryParameters == null || queryParameters.isEmpty) return resolved;

    return resolved.replace(
      queryParameters: queryParameters.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  static String _normalizeBaseUrl(String baseUrl) {
    return baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  }
}
