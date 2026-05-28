import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';
import '../config/app_config.dart';
import 'interceptors/api_error_interceptor.dart';
import 'interceptors/auth_header_interceptor.dart';
import 'interceptors/refresh_token_interceptor.dart';

void _configureDevTls(Dio dio) {
  if (kReleaseMode) return;
  if (!AppConfig.allowBadCertificates) return;

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    },
  );
}

final authDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'accept': 'application/json'},
      responseType: ResponseType.json,
    ),
  );

  _configureDevTls(dio);
  dio.interceptors.add(ApiErrorInterceptor());
  ref.onDispose(dio.close);
  return dio;
});

final dioProvider = Provider<Dio>((ref) {
  final session = ref.read(sessionControllerProvider.notifier);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'accept': 'application/json'},
      responseType: ResponseType.json,
    ),
  );

  _configureDevTls(dio);
  dio.interceptors.add(AuthHeaderInterceptor(session: session));
  dio.interceptors.add(RefreshTokenInterceptor(session: session, dio: dio));
  dio.interceptors.add(ApiErrorInterceptor());

  ref.onDispose(dio.close);
  return dio;
});

final notificationsDioProvider = Provider<Dio>((ref) {
  final session = ref.read(sessionControllerProvider.notifier);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.notificationsBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'accept': 'application/json'},
      responseType: ResponseType.json,
    ),
  );

  _configureDevTls(dio);
  dio.interceptors.add(AuthHeaderInterceptor(session: session));
  dio.interceptors.add(RefreshTokenInterceptor(session: session, dio: dio));
  dio.interceptors.add(ApiErrorInterceptor());

  ref.onDispose(dio.close);
  return dio;
});
