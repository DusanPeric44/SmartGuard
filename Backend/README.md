# SmartGuard Backend (.NET / net10.0)

Backend dio SmartGuard sistema je skup .NET servisa koji obezbjeđuju **REST API**, **real-time SignalR komunikaciju**, **asinhronu obradu (RabbitMQ)** i **arhiviranje snimaka**.

Glavni opis projekta i linkovi na ostale module: [Docs/README.md](../Docs/README.md)

## Servisi i projekti

- `SmartGuard.API` (REST + SignalR): autentifikacija, autorizacija, uređaji, snimci, alarmi, poznate osobe, notifikacije, izvještaji
- `SmartGuard.Archive.Microservice` (worker): preuzimanje i skladištenje snimaka na server (file system)
- `SmartGuard.Notifications.Microservice` (worker): email + push notifikacije
- `SmartGuard.VectorMatching.Microservice` (worker): identifikacija lica (cosine similarity nad embedding vektorima) i objava rezultata nazad prema API-ju
- `SmartGuard.Services` / `SmartGuard.Model`: domen, EF Core i poslovna logika

## Pipeline prepoznavanja lica (na backendu)

U SmartGuard-u, ESP32 šalje sliku + embedding vektor, ali **matching (prepoznavanje identiteta)** se radi na backendu.

### 1) Ingest događaja (API)

- Endpoint: `POST /FaceDetectionEvents/detect`
- Header: `X-Device-Token: <device apiKey>`
- Body (JSON): `{ deviceId, imageBytes, vector }`
  - `imageBytes` je JPEG kao niz bajtova
  - `vector` je 128-dimenzionalni embedding (float[128])

API zatim:
- validira uređaj (deviceId + apiKey),
- sačuva sliku na storage,
- normalizuje embedding (L2 norm) i pakuje ga u `byte[]`,
- upisuje `FaceDetectionEvent` u bazu,
- objavljuje poruku `IVectorMatchRequestedEvent` na RabbitMQ.

### 2) Vector matching (SmartGuard.VectorMatching.Microservice)

Worker konzument prima `IVectorMatchRequestedEvent` i:
- preko gRPC-a pozove API da dobije embedding za taj događaj,
- preko gRPC streaming poziva dobije sve `KnownPerson.Embedding` vektore (centroide),
- izračuna cosine similarity i pronađe najbolji match,
- ako je score >= 0.70 → smatra se match,
- objavi `IVectorMatchCompletedEvent` (FaceDetectionEventId, MatchedPersonId, BestScore, IsMatched).

### 3) Obrada rezultata (SmartGuard.API consumer)

`VectorMatchCompletedConsumer` u API-ju:
- upiše `Score` u `FaceDetectionEvent`,
- ako postoji match:
  - poveže `FaceDetectionEvent.PersonId`,
  - uveća `KnownPerson.DetectionCount`,
  - ažurira `KnownPerson.Embedding` kao centroid (prosjek) iz više event embeddinga,
  - po potrebi kreira alarm i šalje notifikacije na osnovu preferenci.
- ako nema match:
  - kreira novu osobu tipa “Intruder …” i poveže event na nju,
  - kreira alarm i šalje notifikacije (u skladu sa pravilima).

Ovo omogućava da se prepoznavanje skalira i unapređuje bez promjena firmware-a na uređajima.

## Preduvjeti

- .NET SDK (net10.0)
- SQL Server (lokalno ili u kontejneru)
- RabbitMQ (lokalno ili u kontejneru)
- Redis (opcionalno; API ima Redis cache u konfiguraciji)
- Docker (opcionalno; za docker-compose setup)

## Konfiguracija

Strukturna (ne-tajna) konfiguracija je u `appsettings.json` fajlovima za svaki servis:

- REST API: `Backend/SecureGuard/SmartGuard.API/appsettings.json`
- Archive: `Backend/SecureGuard/SmartGuard.Archive.Microservice/appsettings.json`
- Notifications: `Backend/SecureGuard/SmartGuard.Notifications.Microservice/appsettings.json`

**Tajne i okruženje (Docker):** kod pokretanja preko Docker Compose-a tajne i konekcijski podaci
dolaze iz `.env` fajla i injektuju se kao environment varijable koje **override-uju** vrijednosti iz
`appsettings.json` (.NET mapira `Sekcija__Ključ`, npr. `ConnectionStrings__DefaultConnection`,
`Jwt__Secret`, `RabbitMQ__Password`, `Smtp__Password`). Template je u `.env.example`.

Važno:

- `JWT_SECRET` mora biti **identičan** za `SmartGuard.API` i `SmartGuard.Notifications.Microservice`
  (zajednička validacija JWT tokena za SignalR).
- `SmartGuard.Notifications.Microservice` očekuje `firebase-service-account.json` na putanji iz konfiguracije.

## Baza i seed

`SmartGuard.API` pri startu automatski:

- primijeni EF migracije ako postoje pending migracije,
- seed-a referentne tabele,
- seed-a početne korisnike i role.

## Pokretanje (lokalno)

U rootu backenda:

```bash
cd Backend/SecureGuard
dotnet restore
```

### 1) REST API

```bash
cd SmartGuard.API
dotnet run
```

Podrazumijevani portovi (iz `launchSettings.json`):

- `http://localhost:5000`
- `https://localhost:5050`

Swagger je dostupan u Development režimu.

### 2) Archiving microservice

```bash
cd ../SmartGuard.Archive.Microservice
dotnet run
```

Podrazumijevani port: `http://localhost:5001`

### 3) Notifications microservice

```bash
cd ../SmartGuard.Notifications.Microservice
dotnet run
```

Podrazumijevani port: `http://localhost:5002`

## Pokretanje (Docker Compose)

Docker Compose se nalazi na `Backend/SecureGuard/docker-compose.yml` i definiše **7 servisa**:

| Servis                                    | Tip   | Image / build                                | Host port             |
| ----------------------------------------- | ----- | -------------------------------------------- | --------------------- |
| `smartguard.api`                          | app   | build `SmartGuard.API/Dockerfile`            | `5000`, `5010` (gRPC) |
| `smartguard.archive.microservice`         | app   | build `SmartGuard.Archive.Microservice/Dockerfile` | `5001`          |
| `smartguard.notifications.microservice`   | app   | build `SmartGuard.Notifications.Microservice/Dockerfile` | `5002`     |
| `smartguard.vectormatching.microservice`  | app   | build `SmartGuard.VectorMatching.Microservice/Dockerfile` | — (worker) |
| `sqlserver`                               | infra | `mcr.microsoft.com/mssql/server:2022-latest` | `1433`                |
| `rabbitmq`                                | infra | `rabbitmq:3-management`                      | `5672`, `15672`       |
| `redis`                                   | infra | `redis:7-alpine`                             | `6379`                |

Karakteristike compose setupa:

- **Konfiguracija iz `.env`** — svi servisi čitaju tajne i konekcijske podatke iz `.env` (preko
  `environment:` mapiranja na .NET config ključeve, npr. `ConnectionStrings__DefaultConnection`,
  `Jwt__Secret`, `RabbitMQ__Username`). Nema hardkodiranih tajni u compose-u.
- **Interni hostname-ovi** — servisi se međusobno povezuju preko Docker mreže
  (`sqlserver`, `rabbitmq`, `redis`, `smartguard.api`), a ne preko `localhost`.
- **`depends_on` + healthcheck** — aplikativni servisi startaju tek kad su `sqlserver`, `rabbitmq`
  i `redis` u stanju `healthy`.
- **Persistentni volume-i** — `sqlserver_data`, `rabbitmq_data`, `redis_data`.

### 1) Kreiraj `.env`

Compose koristi `.env` varijable (nije verzionisan). Bez `.env` infra servisi neće startati jer
passwordi nemaju default vrijednosti. Kreiraj ga kopiranjem template-a:

```bash
cd Backend/SecureGuard
cp .env.example .env
```

`.env` (vidi `.env.example`) sadrži:

```
RABBITMQ_USER, RABBITMQ_PASSWORD, RABBITMQ_VHOST, RABBITMQ_PORT, RABBITMQ_MANAGEMENT_PORT
REDIS_PASSWORD, REDIS_PORT, REDIS_MAX_MEMORY
SQLSERVER_PORT, SQLSERVER_SA_PASSWORD, SQLSERVER_EDITION, SQLSERVER_DB
```

### 2) Pokreni servise

```bash
docker compose --env-file .env up --build
```

### 3) Dostupni portovi nakon pokretanja

Aplikativni servisi:

- REST API + SignalR: `http://localhost:5000`
- API gRPC (http2): `localhost:5010`
- Archive microservice: `http://localhost:5001`
- Notifications microservice: `http://localhost:5002`

Infrastrukturni servisi:

- SQL Server: `localhost:1433`
- RabbitMQ: `localhost:5672`
- RabbitMQ management UI: `http://localhost:15672`
- Redis: `localhost:6379`

## Korisnički podaci za pristup

Pri prvom pokretanju `SmartGuard.API` seed-a sljedeće naloge (vidi `SmartGuard.Services/DatabaseSeedService.cs`):

| Uloga       | Email                      | Lozinka         |
| ----------- | -------------------------- | --------------- |
| Admin       | `admin@smartguard.com`     | `Admin123!`     |
| HomeOwner   | `homeowner@smartguard.com` | `HomeOwner123!` |
| Viewer      | `viewer@smartguard.com`    | `Viewer123!`    |

Desktop (admin) aplikacija koristi **Admin** nalog; mobilna (klijentska) aplikacija koristi
**HomeOwner** / **Viewer** naloge.

## Povezivanje sa klijentima

- Desktop app koristi `API_BASE_URL` i (po potrebi) `ARCHIVE_BASE_URL`: [Desktop/README.md](../Desktop/README.md)
- Mobile app koristi `API_BASE_URL`: [Mobile/README.md](../Mobile/README.md)
- ESP32 firmware treba da pokazuje na API (SignalR + REST) i upload endpoint: [ESP32/README.md](../ESP32/README.md)
