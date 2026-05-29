import 'auth_models.dart';

abstract interface class ExternalAuthRepository {
  Future<AuthTokens?> signInWithGoogle();
}
