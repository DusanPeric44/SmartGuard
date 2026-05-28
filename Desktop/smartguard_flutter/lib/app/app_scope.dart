import 'package:flutter/widgets.dart';
import 'package:smartguard_flutter/core/auth/auth_controller.dart';
import 'package:smartguard_flutter/core/network/api_client.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.auth,
    required this.api,
    required this.notificationsApi,
    required super.child,
  });

  final AuthController auth;
  final ApiClient api;
  final ApiClient notificationsApi;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope == null) {
      throw StateError('AppScope nije pronađen u widget stablu.');
    }
    return scope;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return auth != oldWidget.auth ||
        api != oldWidget.api ||
        notificationsApi != oldWidget.notificationsApi;
  }
}

