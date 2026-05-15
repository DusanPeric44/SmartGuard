import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:smartguard_flutter/core/network/api_error.dart';

typedef TokenProvider = Future<String?> Function();
typedef UnauthorizedHandler = Future<void> Function();

class ApiClient {
  ApiClient({
    required this.baseUri,
    Dio? dio,
    TokenProvider? tokenProvider,
    UnauthorizedHandler? onUnauthorized,
    Duration timeout = const Duration(seconds: 15),
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: timeout,
               sendTimeout: timeout,
               receiveTimeout: timeout,
             ),
           ),
       _tokenProvider = tokenProvider,
       _onUnauthorized = onUnauthorized,
       _timeout = timeout;

  final Uri baseUri;
  final Dio _dio;
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
      mergedHeaders['Content-Type'] =
          mergedHeaders['Content-Type'] ?? 'application/json';
      if (body is String || body is List<int>) {
        encodedBody = body;
      } else {
        encodedBody = jsonEncode(body);
      }
    }

    try {
      final response = await _dio
          .requestUri<Object?>(
            uri,
            data: encodedBody,
            options: Options(
              method: method,
              headers: mergedHeaders,
              responseType: ResponseType.bytes,
              validateStatus: (_) => true,
              sendTimeout: _timeout,
              receiveTimeout: _timeout,
            ),
          )
          .timeout(_timeout);

      final statusCode = response.statusCode ?? 0;
      final bodyBytes = (response.data as List<int>?) ?? const <int>[];

      if (statusCode == 401) {
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
            statusCode: statusCode,
            uri: uri,
            message: _extractMessage(bodyBytes),
            details: _tryDecodeJson(bodyBytes),
          ),
        );
      }

      if (statusCode < 200 || statusCode >= 300) {
        throw ApiException(
          ApiError(
            kind: _kindForStatus(statusCode),
            statusCode: statusCode,
            uri: uri,
            message: _extractMessage(bodyBytes),
            details: _tryDecodeJson(bodyBytes),
          ),
        );
      }

      final json = _tryDecodeJson(bodyBytes);
      if (decode == null) {
        return json as T;
      }

      try {
        return decode(json);
      } catch (e) {
        throw ApiException(
          ApiError(
            kind: ApiErrorKind.invalidResponse,
            statusCode: statusCode,
            uri: uri,
            message: 'Ne mogu parsirati odgovor.',
            details: e,
          ),
        );
      }
    } on ApiException {
      rethrow;
    } on TimeoutException catch (_) {
      throw ApiException(ApiError(kind: ApiErrorKind.timeout, uri: uri));
    } on DioException catch (e) {
      final err = e.error;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ApiException(ApiError(kind: ApiErrorKind.timeout, uri: uri));
      }
      if (e.type == DioExceptionType.connectionError ||
          err is SocketException) {
        throw ApiException(
          ApiError(
            kind: ApiErrorKind.network,
            uri: uri,
            message: err is SocketException ? err.message : null,
            details: e,
          ),
        );
      }
      throw ApiException(
        ApiError(kind: ApiErrorKind.unknown, uri: uri, details: e),
      );
    } catch (e) {
      throw ApiException(
        ApiError(kind: ApiErrorKind.unknown, uri: uri, details: e),
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

  String? _extractMessage(List<int> bodyBytes) {
    final decoded = _tryDecodeJson(bodyBytes);
    if (decoded is Map) {
      final msg = decoded['message'] ?? decoded['error'] ?? decoded['detail'];
      if (msg is String && msg.trim().isNotEmpty) return msg.trim();
    }
    final text = utf8.decode(bodyBytes, allowMalformed: true).trim();
    return text.isEmpty ? null : text;
  }
}
