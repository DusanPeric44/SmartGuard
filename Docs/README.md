# SmartGuard – Open‑Source IoT sigurnosni sistem

**Vaša kuća. Vaša kontrola. Vaši podaci.**

SmartGuard je **self-hosted IoT sigurnosna solucija** za pametne domove koja kombinuje **ESP32‑CAM edge uređaje**, **.NET backend (REST + SignalR)** i **Flutter mobilnu/desktop aplikaciju**. Fokus projekta je privatnost (podaci ostaju kod korisnika), minimalan storage (event-driven snimanje + ring buffer) i real-time iskustvo (live stream + notifikacije).

## Brzi linkovi (repo)

- Backend (.NET mikroservisi): [Backend/README.md](../Backend/README.md)
- ESP32‑CAM firmware i provisioning: [ESP32/README.md](../ESP32/README.md)
- Mobile (Flutter Android): [Mobile/README.md](../Mobile/README.md)
- Desktop (Flutter admin): [Desktop/README.md](../Desktop/README.md)

## Problem koji rješavamo

Klasična “smart” kućna sigurnost često podrazumijeva:

- mjesečne pretplate za cloud storage,
- nejasne politike obrade lica/snimaka,
- vendor lock-in (prestane servis → prestane vrijednost sistema),
- nepotrebno čuvanje 24/7 video materijala.

SmartGuard pristup je suprotan: **lokalna kontrola + minimalni podaci + otvoren kod**.

## Ključne karakteristike

- **Live stream bez latencije**: ESP32 šalje JPEG frame‑ove, backend radi SignalR relay do klijenata.
- **Event-driven snimanje**: snimci i “archive” nastaju kada se desi relevantan događaj (pokret/lice/alaram), umjesto stalnog snimanja.
- **Ring buffer na SD kartici**: uređaj drži ograničen broj “normalnih” snimaka, a event snimke tretira kao prioritet.
- **Face detection & known persons**: događaji prepoznavanja lica se povezuju sa “poznatim osobama”, uz mogućnost selektivnih obavijesti.
- **Selektivne notifikacije**: push/email samo za tipove događaja i osobe koje korisnik odabere.
- **Sigurnost**: JWT autentifikacija, role‑based autorizacija (Admin/HomeOwner/Viewer), audit trail, soft delete.
- **Skalabilnost**: više ESP32 uređaja, asinhrona obrada preko message brokera.

## Arhitektura (pregled)

SmartGuard je dizajniran kao set komponenti koje jasno razdvajaju real‑time dio, poslovnu logiku i “teške” background operacije:

- **ESP32‑CAM (edge)**: snimanje i lokalni buffer; slanje frame‑ova i event snimaka; Wi‑Fi provisioning.
- **REST API (.NET)**: autentifikacija/autorizacija; CRUD nad entitetima (uređaji, snimci, alarmi, poznate osobe…); SignalR hubovi; publish poruka prema workerima.
- **Notification Worker (.NET)**: konzumira poruke i šalje email + push (FCM).
- **Archiving Worker (.NET)**: preuzima MJPEG snimke sa uređaja i skladišti ih na serveru; ažurira statuse snimaka.
- **SQL Server**: centralna relacijska baza (glavni domen entiteti + referentne tabele).
- **RabbitMQ**: asinhroni tokovi (notifikacije i archiving).
- **Flutter Mobile**: aplikacija za korisnika (live, snimci, alarmi, poznate osobe, notifikacije).
- **Flutter Desktop**: admin panel (upravljanje sistemom, izvještaji, audit).

### Tokovi podataka (sažeto)

- **Live stream**: ESP32 → REST API (frame upload) → SignalR hub → Mobile/Desktop klijent.
- **Event snimak**: ESP32 najavi upload → API objavi poruku → Archiving Worker preuzme snimak → spremi na storage → API ažurira status.
- **Notifikacije**: API objavi poruku → Notification Worker pošalje email/push → SignalR in-app notifikacije.

## Inovativnost

- **Hybrid edge + server**: dio obrade se radi na uređaju (edge), a dio u backendu, uz jasne granice privatnosti.
- **Minimalni podaci po defaultu**: snima se samo ono što ima smisla (događaji), uz ring buffer kao “sigurnosnu mrežu”.
- **Open‑source i auditabilno**: korisnik i žiri mogu pregledati kompletan tok podataka i sigurnosne odluke (auth, audit, state machine).
- **Real-time iskustvo bez cloud lock‑ina**: SignalR “push” tokovi bez posredničkih servisa i pretplata.

## Utjecaj na okruženje

- **Privatnost kao default**: podaci ostaju u lokalnoj infrastrukturi (kuća/firmа) umjesto trećih strana.
- **Budžetski pristup**: ESP32‑CAM uređaji omogućavaju jeftino skaliranje (više kamera bez povećanja pretplate).
- **Primjenjivo u praksi**: kuće, mali biznisi (prodavnice/restorani), apartmanski kompleksi (više korisnika i nivoa pristupa).

## Tehnička realizacija

### Šta je “gotovo rješenje” (koristimo kao building blocks)

- Hardver: ESP32‑CAM + SD kartica
- Framework-ovi: .NET (net10.0), Flutter, SignalR, Entity Framework Core
- Infrastruktura: SQL Server, RabbitMQ (message broker)

### Šta je autorski rad tima (naša implementacija)

- Modeliranje domene i baze (entiteti, relacije, soft delete, audit)
- Backend poslovna logika: state machine za alarme/snimke, ownership provjere, API key autentifikacija za uređaje
- Real-time tokovi: SignalR hubovi + provjera prava pristupa na stream
- Worker servisi: queue potrošači, retry logika, slanje email/push, archiving i struktura storage-a
- Flutter klijenti: UI, navigacija, auth tokovi, filteri/paginacija, master‑detail ekrani, PDF izvještaji (desktop)
- ESP32 firmware tok: provisioning, slanje događaja, lokalni buffer i retry sinhronizacije

## Struktura repozitorija

```
SmartGuard/
  Backend/    # .NET API + mikroservisi + domen model
  ESP32/      # Firmware za ESP32-CAM + provisioning
  Mobile/     # Flutter Android aplikacija
  Desktop/    # Flutter desktop admin aplikacija
  Docs/       # Dokumenti za prijavu i takmičenje
```

Detaljni opisi i setup za svaku komponentu su u README fajlovima iz sekcije “Brzi linkovi”.

## Pokretanje sistema (end-to-end)

Minimalno, za kompletan demo trebaju:

- SQL Server (baza)
- RabbitMQ (queue za worker-e)
- (opcionalno) Redis (keš, prema konfiguraciji API-ja)
- .NET SDK (net10.0) za lokalno pokretanje servisa
- Flutter SDK (za klijente)

### Opcija A: Docker

Docker Compose konfiguracija je dostupna na:

- `Backend/SecureGuard/docker-compose.yml`

Compose podiže:

- `smartguard.api` (REST + SignalR)
- `smartguard.archive.microservice`
- `smartguard.notifications.microservice`
- `sqlserver` (SQL Server 2022)
- `rabbitmq` (RabbitMQ + management UI)
- `redis` (Redis cache)

Za pokretanje je potreban `.env` fajl sa varijablama koje compose koristi (npr. `SQLSERVER_SA_PASSWORD`, `RABBITMQ_USER`, `RABBITMQ_PASSWORD`, `REDIS_PASSWORD`).

Primjer pokretanja iz root-a repozitorija:

```bash
docker compose -f Backend/SecureGuard/docker-compose.yml --env-file Backend/SecureGuard/.env up --build
```

Za mapiranje portova API-ja/Archive servisa na host (npr. `localhost:5000` i `localhost:5001`), vidi [Backend/README.md](../Backend/README.md).

### Opcija B: Lokalno (bez Docker-a)

1. Podigni SQL Server i kreiraj bazu `SmartGuardDb` (connection string je u backend konfiguraciji).
2. Podigni RabbitMQ (default `guest/guest`) i (opcionalno) Redis.
3. Pokreni servise:
   - REST API: prati [Backend/README.md](../Backend/README.md)
   - Archiving Worker: prati [Backend/README.md](../Backend/README.md)
   - Notifications Worker: prati [Backend/README.md](../Backend/README.md)
4. Pokreni klijente:
   - Mobile: [Mobile/README.md](../Mobile/README.md)
   - Desktop: [Desktop/README.md](../Desktop/README.md)
5. Flash i provision ESP32: [ESP32/README.md](../ESP32/README.md)

## Tim

- Dušan Perić (IB230222)
- Marko Milidragović (IB230221)
