import 'package:flutter/foundation.dart';

enum AuthMode { login, register }

enum AuthStatus { idle, validating, submitting, success, error }

enum AuthField { login, firstName, lastName, email, password, confirmPassword }

enum AuthFieldError {
  requiredField,
  invalidEmail,
  passwordTooShort,
  passwordTooLong,
  passwordsDoNotMatch,
}

@immutable
class AuthState {
  const AuthState({
    required this.mode,
    required this.status,
    required this.login,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.fieldErrors,
    required this.passwordVisible,
    required this.confirmPasswordVisible,
    required this.globalErrorMessage,
  });

  const AuthState.initial()
    : mode = AuthMode.login,
      status = AuthStatus.idle,
      login = '',
      firstName = '',
      lastName = '',
      email = '',
      password = '',
      confirmPassword = '',
      fieldErrors = const {},
      passwordVisible = false,
      confirmPasswordVisible = false,
      globalErrorMessage = null;

  final AuthMode mode;
  final AuthStatus status;

  final String login;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String confirmPassword;

  final Map<AuthField, AuthFieldError?> fieldErrors;

  final bool passwordVisible;
  final bool confirmPasswordVisible;

  final String? globalErrorMessage;

  bool get isSubmitting => status == AuthStatus.submitting;

  bool get canSubmit {
    if (status == AuthStatus.submitting) return false;
    if (mode == AuthMode.login) {
      return login.trim().isNotEmpty && password.trim().isNotEmpty;
    }
    return firstName.trim().isNotEmpty &&
        lastName.trim().isNotEmpty &&
        email.trim().isNotEmpty &&
        password.trim().isNotEmpty &&
        confirmPassword.trim().isNotEmpty;
  }

  AuthState copyWith({
    AuthMode? mode,
    AuthStatus? status,
    String? login,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? confirmPassword,
    Map<AuthField, AuthFieldError?>? fieldErrors,
    bool? passwordVisible,
    bool? confirmPasswordVisible,
    String? globalErrorMessage,
  }) {
    return AuthState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      login: login ?? this.login,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      passwordVisible: passwordVisible ?? this.passwordVisible,
      confirmPasswordVisible:
          confirmPasswordVisible ?? this.confirmPasswordVisible,
      globalErrorMessage: globalErrorMessage,
    );
  }
}
