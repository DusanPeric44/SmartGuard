import '../constants/app_strings.dart';
import '../network/api_error.dart';
import 'ui_error.dart';

class UiErrorMapper {
  const UiErrorMapper();

  UiError fromApiError(ApiError error) {
    if (error.type == ApiErrorType.http) {
      if (error.statusCode == 401) {
        return const UiError(
          type: UiErrorType.unauthorized,
          message: AppStrings.errorUnauthorized,
        );
      }
      if (error.validation.isNotEmpty) {
        return UiError(
          type: UiErrorType.validation,
          message: error.message,
        );
      }
      return UiError(type: UiErrorType.server, message: error.message);
    }

    return switch (error.type) {
      ApiErrorType.network => const UiError(
        type: UiErrorType.network,
        message: AppStrings.errorNetwork,
      ),
      ApiErrorType.timeout => const UiError(
        type: UiErrorType.timeout,
        message: AppStrings.errorTimeout,
      ),
      ApiErrorType.invalidResponse => const UiError(
        type: UiErrorType.unknown,
        message: AppStrings.errorUnknown,
      ),
      ApiErrorType.http => UiError(type: UiErrorType.server, message: error.message),
    };
  }
}

