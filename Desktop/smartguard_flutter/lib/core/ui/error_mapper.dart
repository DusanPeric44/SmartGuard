import 'package:smartguard_flutter/core/network/api_error.dart';

class UiErrorMapper {
  const UiErrorMapper._();

  static String toMessage(Object error) {
    if (error is ApiException) {
      final apiError = error.error;
      final backendMessage = _extractBackendMessage(apiError);
      switch (apiError.kind) {
        case ApiErrorKind.network:
          return 'Nema konekcije. Provjerite internet i pokušajte ponovo.';
        case ApiErrorKind.timeout:
          return 'Zahtjev je istekao. Pokušajte ponovo.';
        case ApiErrorKind.unauthorized:
          return backendMessage ?? 'Niste autorizovani. Prijavite se ponovo.';
        case ApiErrorKind.forbidden:
          return 'Nemate dozvolu za ovu akciju.';
        case ApiErrorKind.notFound:
          return 'Traženi resurs nije pronađen.';
        case ApiErrorKind.validation:
          return backendMessage ?? 'Provjerite unesene podatke.';
        case ApiErrorKind.server:
          return 'Greška na serveru. Pokušajte kasnije.';
        case ApiErrorKind.invalidResponse:
          return 'Neispravan odgovor sa servera.';
        case ApiErrorKind.unknown:
          return backendMessage ?? 'Nešto je pošlo po zlu.';
      }
    }

    return 'Nešto je pošlo po zlu.';
  }

  static String? _extractBackendMessage(ApiError error) {
    final direct = error.message?.trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final details = error.details;
    if (details is Map) {
      final genericCandidates = [
        details['message'],
        details['error'],
        details['detail'],
      ];
      for (final candidate in genericCandidates) {
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }

      final nestedErrors = details['errors'];
      if (nestedErrors is Map) {
        for (final value in nestedErrors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first;
            if (first is String && first.trim().isNotEmpty) {
              return first.trim();
            }
          }
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }
    }

    return null;
  }
}
