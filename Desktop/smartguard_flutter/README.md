# SmartGuard Desktop

Administrativna (desktop) Flutter aplikacija za SmartGuard sigurnosni sistem
(Windows / macOS / Linux). Sadrži upravljanje uređajima, korisnicima,
snimcima, alarmima, poznatim osobama, PDF izvještajima, audit logovima i
referentnim podacima (šifarnicima).

## Pokretanje aplikacije

Adresa API-ja se postavlja preko `--dart-define=API_BASE_URL`. Za lokalno
pokretanje desktop aplikacije koristi se `localhost`:

```bash
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5000
# ili: flutter run -d macos / -d linux
```

Vrijednost se u kodu čita preko `String.fromEnvironment('API_BASE_URL')`
(`lib/core/config/app_config.dart`).

### Korisnički podaci za prijavu

Desktop dio je administrativni — prijava je dozvoljena samo `Admin` ulozi.

| Uloga | Korisničko ime | Lozinka |
| ----- | -------------- | ------- |
| Admin | `desktop`      | `test`  |

> Kredencijali moraju odgovarati seed podacima backend servisa.

## Build (Windows)

```bash
flutter clean
flutter build windows --release
```

Generisani fajlovi se nalaze na putanji:

```
build/windows/x64/runner/Release/
```

## Arhitektura

- `lib/core/`: konfiguracija (`AppConfig`), HTTP klijent (`ApiClient` sa 401
  refresh logikom), auth (token store, `AuthController`), realtime (SignalR),
  notifikacije, error mapping.
- `lib/app/`: `AppScope` (InheritedWidget sa `auth` i `api`), `go_router`
  ruter (admin-only redirecti), shell (NavigationRail + AppBar), navigacija,
  tema.
- `lib/features/<feature>/`: `data/` (repository + API implementacija),
  `model/`, `viewmodel/` (ChangeNotifier), screen + `widgets/`.
- `lib/shared/widgets/`: zajedničke komponente (`AsyncStatePanel`,
  `CachedBase64Image`).

## Funkcionalnosti

- **Dashboard**: KPI pregled sa grafikonima (fl_chart).
- **Uređaji**: lista + provisioning wizard + detalji.
- **Korisnici**: CRUD (kreiranje, izmjena, brisanje, uloge).
- **Snimci**: pretraga/filteri, reprodukcija, soft delete, download.
- **Alarmi**: lista sa filterima i detaljima, potvrda/odbijanje/rješavanje.
- **Poznate osobe**: lista, izmjena, brisanje, merge, detekcije.
- **PDF izvještaji**: generisanje sa rasponom datuma i preuzimanje.
- **Audit logovi**: pretraga i filteri po korisniku/akciji/resursu/statusu.
- **Referentni podaci (šifarnici)**: CRUD za države, gradove (FK na državu),
  tipove/statuse alarma, statuse uređaja, tipove/statuse snimaka.

## Networking i greške

- Svi HTTP pozivi idu preko `ApiClient` (`lib/core/network/api_client.dart`).
- 401 → single-flight refresh tokena + retry; neuspjeh → logout + redirect na
  login (router guard).
- Backend validacijske poruke se ne prikrivaju: parsiraju se u `ApiClient` i
  mapiraju u `UiErrorMapper`.
