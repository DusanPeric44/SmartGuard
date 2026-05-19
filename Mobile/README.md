# SmartGuard Mobile (Flutter Android)

Mobilna aplikacija je namijenjena vlasniku kuće (HomeOwner): **live stream**, pregled snimaka, alarmi, poznate osobe, notifikacije i podešavanje preferencija obavijesti.

Glavni opis projekta i linkovi na ostale module: [Docs/README.md](../Docs/README.md)

## Lokacija koda

Flutter projekat se nalazi u:

- `Mobile/smartguard_mobile`

## Preduvjeti

- Flutter SDK
- Android Studio + emulator ili fizički Android uređaj
- Pokrenut backend: [Backend/README.md](../Backend/README.md)

## Konfiguracija (API_BASE_URL)

Mobilna app čita `API_BASE_URL` kroz `--dart-define`.

Podrazumijevana vrijednost je prilagođena Android emulatoru:

- `http://10.0.2.2:5000`

Primjeri:

```bash
cd Mobile/smartguard_mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

Za fizički uređaj, koristi IP adresu mašine na kojoj radi backend:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.x.y:5000
```

## Dev napomene

- Ako testirate HTTPS sa self-signed certifikatima, opcionalno se koristi `ALLOW_BAD_CERTS=true`:

```bash
flutter run --dart-define=API_BASE_URL=https://192.168.x.y:5050 --dart-define=ALLOW_BAD_CERTS=true
```
