import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:smartguard_flutter/core/network/api_error.dart';

typedef TokenProvider = Future<String?> Function();
typedef UnauthorizedHandler = Future<void> Function();

class ApiClient {
  ApiClient({
    required this.baseUri,
    http.Client? httpClient,
    TokenProvider? tokenProvider,
    UnauthorizedHandler? onUnauthorized,
    Duration timeout = const Duration(seconds: 15),
  })  : _http = httpClient ?? http.Client(),
        _tokenProvider = tokenProvider,
        _onUnauthorized = onUnauthorized,
        _timeout = timeout;

  final Uri baseUri;
  final http.Client _http;
  final TokenProvider? _tokenProvider;
  final UnauthorizedHandler? _onUnauthorized;
  final Duration _timeout;
  bool _isHandlingUnauthorized = false;

  Future<T> get<T>(
    String path, {
    Map<String, String>? headers,
    T Function(Object? json)? decode,
  }) {
    return request<T>(
      method: 'GET',
      path: path,
      headers: headers,
      decode: decode,
    );
  }

  Future<T> post<T>(
    String path, {
    Map<String, String>? headers,
    Object? body,
    T Function(Object? json)? decode,
  }) {
    return request<T>(
      method: 'POST',
      path: path,
      headers: headers,
      body: body,
      decode: decode,
    );
  }

  Future<T> request<T>({
    required String method,
    required String path,
    Map<String, String>? headers,
    Object? body,
    T Function(Object? json)? decode,
  }) async {
    final uri = _resolve(path);
    final mergedHeaders = <String, String>{
      'Accept': 'application/json',
      ...?headers,
    };

    final token = await _tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      mergedHeaders['Authorization'] = 'Bearer $token';
    }

    Object? encodedBody;
    if (body != null) {
      mergedHeaders['Content-Type'] = mergedHeaders['Content-Type'] ?? 'application/json';
      if (body is String || body is List<int>) {
        encodedBody = body;
      } else {
        encodedBody = jsonEncode(body);
      }
    }

    http.Response response;
    try {
      final req = http.Request(method, uri);
      req.headers.addAll(mergedHeaders);
      if (encodedBody != null) {
        if (encodedBody is String) {
          req.body = encodedBody;
        } else if (encodedBody is List<int>) {
          req.bodyBytes = encodedBody;
        } else {
          req.body = encodedBody.toString();
        }
      }

      final streamed = await _http.send(req).timeout(_timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException catch (_) {
      throw ApiException(
        ApiError(kind: ApiErrorKind.timeout, uri: uri),
      );
    } on SocketException catch (e) {
      throw ApiException(
        ApiError(kind: ApiErrorKind.network, uri: uri, message: e.message),
      );
    } catch (e) {
      throw ApiException(
        ApiError(kind: ApiErrorKind.unknown, uri: uri, details: e),
      );
    }

    if (response.statusCode == 401) {
      if (!_isHandlingUnauthorized) {
        _isHandlingUnauthorized = true;
        try {
          await _onUnauthorized?.call();
        } finally {
          _isHandlingUnauthorized = false;
        }
      }
      throw ApiException(
        ApiError(
          kind: ApiErrorKind.unauthorized,
          statusCode: response.statusCode,
          uri: uri,
          message: _extractMessage(response),
          details: _tryDecodeJson(response.bodyBytes),
        ),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        ApiError(
          kind: _kindForStatus(response.statusCode),
          statusCode: response.statusCode,
          uri: uri,
          message: _extractMessage(response),
          details: _tryDecodeJson(response.bodyBytes),
        ),
      );
    }

    if (decode == null) {
      final json = _tryDecodeJson(response.bodyBytes);
      return json as T;
    }

    final json = _tryDecodeJson(response.bodyBytes);
    try {
      return decode(json);
    } catch (e) {
      throw ApiException(
        ApiError(
          kind: ApiErrorKind.invalidResponse,
          statusCode: response.statusCode,
          uri: uri,
          message: 'Ne mogu parsirati odgovor.',
          details: e,
        ),
      );
    }
  }

  Uri _resolve(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return baseUri.resolve(normalized);
  }

  ApiErrorKind _kindForStatus(int statusCode) {
    if (statusCode == 403) return ApiErrorKind.forbidden;
    if (statusCode == 404) return ApiErrorKind.notFound;
    if (statusCode == 422) return ApiErrorKind.validation;
    if (statusCode >= 500) return ApiErrorKind.server;
    return ApiErrorKind.unknown;
  }

  Object? _tryDecodeJson(List<int> bytes) {
    if (bytes.isEmpty) return null;
    final text = utf8.decode(bytes, allowMalformed: true).trim();
    if (text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } catch (_) {
      return text;
    }
  }

  String? _extractMessage(http.Response response) {
    final decoded = _tryDecodeJson(response.bodyBytes);
    if (decoded is Map) {
      final msg = decoded['message'] ?? decoded['error'] ?? decoded['detail'];
      if (msg is String && msg.trim().isNotEmpty) return msg.trim();
    }
    final text = utf8.decode(response.bodyBytes, allowMalformed: true).trim();
    return text.isEmpty ? null : text;
  }
}
