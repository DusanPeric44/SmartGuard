import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../api_error.dart';

class ApiErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is ApiError) {
      handler.next(err);
      return;
    }

    final apiError = _map(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiError,
        message: apiError.message,
        stackTrace: err.stackTrace,
      ),
    );
  }

  ApiError _map(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return ApiError.timeout(err);
    }

    final underlying = err.error;
    if (underlying is SocketException) {
      return ApiError.network(underlying);
    }
    if (underlying is IOException) {
      return ApiError.network(underlying);
    }

    final response = err.response;
    if (response != null) {
      final statusCode = response.statusCode ?? 0;
      final headers = response.headers.map.map(
        (k, v) => MapEntry(k.toLowerCase(), v.join(', ')),
      );
      final body = _stringBody(response.data);
      return ApiError.fromHttpResponse(
        statusCode: statusCode,
        body: body,
        headers: headers,
      );
    }

    return ApiError.network(err);
  }

  String _stringBody(Object? data) {
    if (data == null) return '';
    if (data is String) return data;
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }
}
