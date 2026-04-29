# SmartGuardFlutter (skeleton)

Flutter skeleton aplikacija za SmartGuard: navigacija + placeholder ekrani + infrastruktura (API config, networking, auth/401, deep links) kao baza za timski razvoj.

## API base URL (API_BASE_URL)

Podrazumijevani base URL je `http://localhost:8080`.

Override kroz `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Za testove (ako želite verifikovati override ponašanje):

```bash
flutter test --dart-define=API_BASE_URL=http://example.test
```

## Struktura projekta

- `lib/app.dart`: `MaterialApp.router` + tema + start deep link handler-a
- `lib/core/config`: konfiguracija (`AppConfig`)
- `lib/core/network`: `ApiClient`, `ApiError/ApiResult`, response handler, transport sloj + auth transport
- `lib/core/auth`: session state, token storage (secure storage), refresh stub
- `lib/core/navigation`: `go_router`, shell (top bar + bottom nav), deep link handler/mapper
- `lib/core/theme`: osnovni tokens (boje/tipografija) i `ThemeData`
- `lib/features/<feature>`:
  - `domain/`: modeli i repository interfejsi (+ stub implementacija)
  - `application/`: controller/state (Riverpod) i provider-i
  - `presentation/`: ekran/widget (placeholder)

## Dodavanje novog feature-a

Kopi/pattern za novi feature se nalazi u:

- `lib/features/feature_template/*`

Tipični koraci:

1. Dodaj `domain` repository interfejs (i stub).
2. Dodaj `application` state + controller (Riverpod provider).
3. Dodaj `presentation` screen koji koristi `ref.watch(...)` i zove `notifier.refresh()` ili slične akcije.
4. Uključi novu rutu u `lib/core/navigation/app_router.dart` (ako je ekran navigabilan).

## Networking i greške

- Svi HTTP pozivi idu preko `ApiClient` (`lib/core/network/api_client.dart`).
- Backend validacijske poruke se ne prikrivaju: parsing je u `api_response_handler.dart`, a greška je predstavljena kroz `ApiError`.

## Auth i 401

- Tokeni su u secure storage (`lib/core/auth/secure_token_storage.dart`).
- 401 handling je u `AuthHttpTransport` i radi:
  - attach access token
  - single-flight refresh (trenutno stub, vidi `StubTokenRefresher`)
  - retry original request
  - logout + redirect na login ako refresh ne uspije

## Deep links

- Initial link + resumed scenario su podržani kroz `DeepLinkHandler`.
- Mapiranje link → ruta je u `DeepLinkMapper` i trenutno je placeholder dok Plan PDF ne definiše finalne formate.

## Performanse

- Nezavisne async operacije paralelizuj preko `Future.wait()` (helper: `lib/core/utils/futures.dart`).
- Base64 slike dekodiraj van `build()` i keširaj:
  - `Base64BytesCache` (`lib/core/images/base64_bytes_cache.dart`)
  - widget helper: `Base64Image` (`lib/core/images/base64_image.dart`)

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
