import 'auth_models.dart';

abstract interface class AuthRepository {
  Future<AuthTokens> login({required String email, required String password});
  Future<AuthTokens> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });
}
