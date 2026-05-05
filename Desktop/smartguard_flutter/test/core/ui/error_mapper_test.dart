import 'package:flutter_test/flutter_test.dart';
import 'package:smartguard_flutter/core/network/api_error.dart';
import 'package:smartguard_flutter/core/ui/error_mapper.dart';

void main() {
  group('UiErrorMapper', () {
    test('preserves backend validation message', () {
      final error = ApiException(
        ApiError(
          kind: ApiErrorKind.validation,
          details: const {
            'errors': {
              'username': ['Korisnicko ime je obavezno.'],
            },
          },
        ),
      );

      expect(
        UiErrorMapper.toMessage(error),
        'Korisnicko ime je obavezno.',
      );
    });

    test('maps network error to user-friendly message', () {
      final error = ApiException(
        const ApiError(kind: ApiErrorKind.network),
      );

      expect(
        UiErrorMapper.toMessage(error),
        'Nema konekcije. Provjerite internet i pokušajte ponovo.',
      );
    });
  });
}
