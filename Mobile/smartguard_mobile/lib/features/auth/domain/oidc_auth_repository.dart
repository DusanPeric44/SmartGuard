import 'auth_models.dart';

abstract interface class OidcAuthRepository {
  Future<AuthTokens?> signInWithGoogle();
}

