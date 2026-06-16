# SmartGuard Mobile

Klijentska (mobilna) Flutter aplikacija za SmartGuard — sistem za nadzor sigurnosnih kamera: live stream, arhiva snimaka, alarmi, poznate osobe, notifikacije i profil korisnika.

## Pokretanje aplikacije

Aplikacija čita adresu API-ja iz `--dart-define=API_BASE_URL`. Podrazumijevana
vrijednost je `http://10.0.2.2:5000` (standardna adresa za Android emulator AVD).

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

Vrijednost se u kodu čita preko `String.fromEnvironment('API_BASE_URL')`
(`lib/core/config/app_config.dart`).

### Korisnički podaci za prijavu

| Uloga              | Korisničko ime | Lozinka |
| ------------------ | -------------- | ------- |
| Mobilni korisnik   | `mobile`       | `test`  |

> Kredencijali moraju odgovarati seed podacima backend servisa.

## Build (Android APK)

```bash
flutter clean
flutter build apk --release
```

Generisani APK se nalazi na putanji:

```
build/app/outputs/flutter-apk/app-release.apk
```

## Struktura projekta

- `lib/app.dart`: `MaterialApp.router` + tema + start deep link / push handler-a
- `lib/core/config`: konfiguracija (`AppConfig`) — sve adrese preko `String.fromEnvironment`
- `lib/core/network`: Dio setup (`dio_provider.dart`) + interceptori (`AuthHeaderInterceptor`, `RefreshTokenInterceptor`, `ApiErrorInterceptor`) + `ApiError`
- `lib/core/auth`: session state, token storage (secure storage), token refresh (`TokenRefresher`)
- `lib/core/navigation`: `go_router`, shell (top bar + bottom nav), deep link handler/mapper
- `lib/core/realtime`: SignalR klijent (live stream + notifikacije)
- `lib/core/push`: Firebase Cloud Messaging (push notifikacije)
- `lib/core/theme`: boje, tipografija i `ThemeData`
- `lib/features/<feature>`:
  - `domain/`: modeli i repository interfejsi (+ API implementacija)
  - `application/`: controller/state (Riverpod) i provider-i
  - `presentation/`: ekrani i widget-i

## Funkcionalnosti

- **Dashboard (master-detail)**: pregled sistema + lista uređaja; odabir uređaja otvara detalj uređaja sa pripadajućim alarmima i snimcima.
- **Live stream**: real-time video preko SignalR-a, snimanje klipa, fullscreen.
- **Arhiva snimaka**: paginirana lista, reprodukcija, preuzimanje (uz autorizaciju po ulozi).
- **Alarmi**: potvrda/odbijanje sa razlogom i audit prikazom; state-machine Pending → Confirmed → Resolved.
- **Poznate osobe**: lista i postavke notifikacija po osobi.
- **Notifikacije**: auto-refresh preko SignalR-a (bez ručnog osvježavanja).
- **Profil**: pregled i izmjena ličnih podataka, promjena lozinke.

## Networking i greške

- Svi HTTP pozivi idu preko Dio (`lib/core/network/dio_provider.dart`).
- `dioProvider` je glavni klijent za REST pozive (auth header + refresh-on-401 + error mapping).
- `authDioProvider` je auth-only klijent za login/refresh pozive (bez refresh interceptora).
- Backend validacijske poruke se ne prikrivaju: `ApiError.fromHttpResponse(...)` parsira `message` i validation map-u, a UI mapping je u `UiErrorMapper`.

## Auth i 401

- Tokeni su u secure storage (`lib/core/auth/secure_token_storage.dart`).
- 401 handling je u `RefreshTokenInterceptor`:
  - attach access tokena preko `AuthHeaderInterceptor`
  - single-flight refresh preko `SessionController.refreshTokensSingleFlight()`
  - retry originalnog zahtjeva jednom sa novim tokenom
  - logout + redirect na login (router guard) ako refresh ne uspije

## Deep links i push

- Initial link + resumed scenario su podržani kroz `DeepLinkHandler`.
- Push notifikacije (FCM) rutaju na odgovarajući ekran nakon prijave (`lib/core/push`).
