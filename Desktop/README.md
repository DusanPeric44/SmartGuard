# SmartGuard Desktop (Flutter Admin)

Desktop aplikacija je **admin panel** za SmartGuard sistem: upravljanje korisnicima i uređajima, pregled snimaka i alarma, audit log i generisanje PDF izvještaja.

Glavni opis projekta i linkovi na ostale module: [Docs/README.md](../Docs/README.md)

## Lokacija koda

Flutter projekat se nalazi u:

- `Desktop/smartguard_flutter`

## Preduvjeti

- Flutter SDK
- Backend servisi pokrenuti lokalno ili dostupni na mreži: [Backend/README.md](../Backend/README.md)

## Konfiguracija (API_BASE_URL / ARCHIVE_BASE_URL)

Desktop app čita konfiguraciju preko `--dart-define`:

- `API_BASE_URL` (default: `http://localhost:5000`)
- `ARCHIVE_BASE_URL` (default: isto kao `API_BASE_URL`)

Primjer:

```bash
cd Desktop/smartguard_flutter
flutter pub get
flutter run -d macos --dart-define=API_BASE_URL=http://localhost:5000 --dart-define=ARCHIVE_BASE_URL=http://localhost:5001
```

## Build

```bash
cd Desktop/smartguard_flutter
flutter build macos --release --dart-define=API_BASE_URL=http://localhost:5000 --dart-define=ARCHIVE_BASE_URL=http://localhost:5001
```

Za Windows koristiti:

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5000 --dart-define=ARCHIVE_BASE_URL=http://localhost:5001
```
