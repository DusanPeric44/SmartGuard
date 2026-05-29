import '../auth_constants.dart';
import 'auth_state.dart';

class AuthValidation {
  const AuthValidation._();

  static final RegExp _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static Map<AuthField, AuthFieldError?> validate(AuthState state) {
    final errors = <AuthField, AuthFieldError?>{};

    if (state.mode == AuthMode.login) {
      if (state.login.trim().isEmpty) {
        errors[AuthField.login] = AuthFieldError.requiredField;
      }
      final passwordError = _validatePassword(state.password);
      if (passwordError != null) {
        errors[AuthField.password] = passwordError;
      }
      return errors;
    }

    if (state.firstName.trim().isEmpty) {
      errors[AuthField.firstName] = AuthFieldError.requiredField;
    }
    if (state.lastName.trim().isEmpty) {
      errors[AuthField.lastName] = AuthFieldError.requiredField;
    }
    final email = state.email.trim();
    if (email.isEmpty) {
      errors[AuthField.email] = AuthFieldError.requiredField;
    } else if (!_emailRegExp.hasMatch(email)) {
      errors[AuthField.email] = AuthFieldError.invalidEmail;
    }

    final passwordError = _validatePassword(state.password);
    if (passwordError != null) {
      errors[AuthField.password] = passwordError;
    }

    if (state.confirmPassword.trim().isEmpty) {
      errors[AuthField.confirmPassword] = AuthFieldError.requiredField;
    } else if (state.confirmPassword != state.password) {
      errors[AuthField.confirmPassword] = AuthFieldError.passwordsDoNotMatch;
    }

    return errors;
  }

  static AuthFieldError? _validatePassword(String password) {
    final trimmed = password.trim();
    if (trimmed.isEmpty) return AuthFieldError.requiredField;
    if (trimmed.length < AuthConstraints.minPasswordLength) {
      return AuthFieldError.passwordTooShort;
    }
    if (trimmed.length > AuthConstraints.maxPasswordLength) {
      return AuthFieldError.passwordTooLong;
    }
    return null;
  }
}
