import 'api_error.dart';

sealed class ApiResult<T> {
  const ApiResult();

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(ApiError error) onFailure,
  });
}

final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);

  final T data;

  @override
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(ApiError error) onFailure,
  }) {
    return onSuccess(data);
  }
}

final class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.error);

  final ApiError error;

  @override
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(ApiError error) onFailure,
  }) {
    return onFailure(error);
  }
}
