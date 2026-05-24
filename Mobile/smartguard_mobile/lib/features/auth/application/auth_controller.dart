import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/api_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/flutter_appauth_oidc_auth_repository.dart';
import '../domain/oidc_auth_repository.dart';
import 'auth_state.dart';
import 'auth_validation.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(ref.read(authDioProvider));
});

final oidcAuthRepositoryProvider = Provider<OidcAuthRepository>((ref) {
  return FlutterAppAuthOidcAuthRepository();
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState.initial();
  }

  void setMode(AuthMode mode) {
    if (state.mode == mode) return;
    state = state.copyWith(
      mode: mode,
      status: AuthStatus.idle,
      fieldErrors: const {},
      globalErrorMessage: null,
    );
  }

  void setLogin(String value) {
    state = state.copyWith(login: value, globalErrorMessage: null);
  }

  void setFullName(String value) {
    state = state.copyWith(fullName: value, globalErrorMessage: null);
  }

  void setEmail(String value) {
    state = state.copyWith(email: value, globalErrorMessage: null);
  }

  void setPassword(String value) {
    state = state.copyWith(password: value, globalErrorMessage: null);
  }

  void setConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value, globalErrorMessage: null);
  }

  void togglePasswordVisible() {
    state = state.copyWith(passwordVisible: !state.passwordVisible);
  }

  void toggleConfirmPasswordVisible() {
    state = state.copyWith(
      confirmPasswordVisible: !state.confirmPasswordVisible,
    );
  }

  Future<void> submit() async {
    state = state.copyWith(
      status: AuthStatus.validating,
      globalErrorMessage: null,
    );
    final errors = AuthValidation.validate(state);
    if (errors.isNotEmpty) {
      state = state.copyWith(status: AuthStatus.error, fieldErrors: errors);
      return;
    }

    state = state.copyWith(
      status: AuthStatus.submitting,
      fieldErrors: const {},
    );
    try {
      final repo = ref.read(authRepositoryProvider);

      final tokens = switch (state.mode) {
        AuthMode.login => await repo.login(
          email: state.login.trim(),
          password: state.password,
        ),
        AuthMode.register => await repo.register(
          fullName: state.fullName.trim(),
          email: state.email.trim(),
          password: state.password,
        ),
      };

      await ref
          .read(sessionControllerProvider.notifier)
          .setTokens(tokens.toSessionTokens());

      state = state.copyWith(status: AuthStatus.success);
    } catch (e) {
      final mapped = _mapError(e);
      state = state.copyWith(
        status: AuthStatus.error,
        fieldErrors: mapped.fieldErrors,
        globalErrorMessage: mapped.globalMessage,
      );
    }
  }

  Future<void> signInWithGoogle() async {
    if (state.isSubmitting) return;

    state = state.copyWith(
      status: AuthStatus.submitting,
      fieldErrors: const {},
      globalErrorMessage: null,
    );

    try {
      final repo = ref.read(oidcAuthRepositoryProvider);
      final tokens = await repo.signInWithGoogle();
      if (tokens == null) {
        state = state.copyWith(status: AuthStatus.idle);
        return;
      }

      await ref
          .read(sessionControllerProvider.notifier)
          .setTokens(tokens.toSessionTokens());

      state = state.copyWith(status: AuthStatus.success);
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        globalErrorMessage: AppStrings.errorOAuthLoginFailed,
      );
    }
  }

  _AuthErrorMapping _mapError(Object error) {
    if (error is ApiError) {
      final global = switch (error.type) {
        ApiErrorType.network => AppStrings.errorNetwork,
        ApiErrorType.timeout => AppStrings.errorTimeout,
        ApiErrorType.invalidResponse => AppStrings.errorUnknown,
        ApiErrorType.http => error.message,
      };

      final fieldErrors = <AuthField, AuthFieldError?>{};

      for (final entry in error.validation.entries) {
        final key = entry.key.toLowerCase();
        if (key.contains('email')) {
          fieldErrors[AuthField.email] = AuthFieldError.invalidEmail;
        } else if (key.contains('password')) {
          fieldErrors[AuthField.password] = AuthFieldError.passwordTooShort;
        } else if (key.contains('login') || key.contains('username')) {
          fieldErrors[AuthField.login] = AuthFieldError.requiredField;
        }
      }

      return _AuthErrorMapping(fieldErrors: fieldErrors, globalMessage: global);
    }

    return const _AuthErrorMapping(
      fieldErrors: {},
      globalMessage: AppStrings.errorUnknown,
    );
  }
}

class _AuthErrorMapping {
  const _AuthErrorMapping({
    required this.fieldErrors,
    required this.globalMessage,
  });

  final Map<AuthField, AuthFieldError?> fieldErrors;
  final String globalMessage;
}
