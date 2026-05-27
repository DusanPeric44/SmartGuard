# SmartGuard ESP32‑CAM (firmware)

ESP32 dio SmartGuard sistema je firmware za ESP32‑CAM koji omogućava:

- slanje live JPEG frame‑ova prema backendu (SignalR relay kroz API),
- lokalno čuvanje snimaka na SD kartici (buffer + event snimci),
- detekciju lica i ekstrakciju embedding vektora (128 float vrijednosti),
- slanje slike + embeddinga prema backendu radi prepoznavanja identiteta,
- provisioning Wi‑Fi kredencijala kroz AP režim,
- autentifikaciju uređaja prema backendu putem API ključa.

Glavni opis projekta i linkovi na ostale module: [Docs/README.md](../Docs/README.md)

## Lokacija koda

- Firmware: `ESP32/SmartGuard/SmartGuard.ino`

## Preduvjeti

- ESP32‑CAM + SD kartica
- Arduino IDE ili PlatformIO
- Pokrenut backend (API + archive worker): [Backend/README.md](../Backend/README.md)

## Konfiguracija backend URL‑ova

U `SmartGuard.ino` se nalaze konstante koje treba prilagoditi vašoj mreži:

- adresa/port API-ja (live stream, registracija uređaja, upload događaja lica)
- adresa upload endpointa (archive servis)

Tipično:

- `API` → `http://<ip-backenda>:5000`
- `Archive upload` → `http://<ip-backenda>:5001/upload`

Endpointi koje firmware koristi:

- `POST /Devices/register` (registracija uređaja; dobija `apiKey` i `id`)
- `POST /FaceDetectionEvents/detect` (slanje JPEG + embedding vektora; header `X-Device-Token`)

Važno: ESP32 ne radi prepoznavanje identiteta (matching na bazu poznatih osoba). To se radi na backendu.

## Flash

1. Otvori `ESP32/SmartGuard/SmartGuard.ino`
2. Izaberi ispravan board (ESP32‑CAM) i port
3. Podesi konfiguraciju (URL-ovi) i flash na uređaj

## Wi‑Fi provisioning (AP mode)

Nakon flasha, uređaj diže access point:

- SSID: `ESP32-SmartCam-AP`

Zatim pošalji provisioning podatke na uređaj (form-data ili urlencoded):

```bash
curl -X POST \"http://192.168.4.1/provision\" \\
  -H \"Content-Type: application/x-www-form-urlencoded\" \\
  --data-urlencode \"ssid=YOUR_WIFI_SSID\" \\
  --data-urlencode \"password=YOUR_WIFI_PASSWORD\" \\
  --data-urlencode \"apiKey=YOUR_DEVICE_API_KEY\"
```

`apiKey` je ključ koji uređaj koristi za autentifikaciju prema backendu (generiše se/sprema na backend strani pri registraciji uređaja).
