# SmartGuard Backend (.NET / net10.0)

Backend dio SmartGuard sistema je skup .NET servisa koji obezbjeđuju **REST API**, **real-time SignalR komunikaciju**, **asinhronu obradu (RabbitMQ)** i **arhiviranje snimaka**.

Glavni opis projekta i linkovi na ostale module: [Docs/README.md](../Docs/README.md)

## Servisi i projekti

- `SmartGuard.API` (REST + SignalR): autentifikacija, autorizacija, uređaji, snimci, alarmi, poznate osobe, notifikacije, izvještaji
- `SmartGuard.Archive.Microservice` (worker): preuzimanje i skladištenje snimaka na server (file system)
- `SmartGuard.Notifications.Microservice` (worker): email + push notifikacije
- `SmartGuard.Services` / `SmartGuard.Model`: domen, EF Core i poslovna logika

## Preduvjeti

- .NET SDK (net10.0)
- SQL Server (lokalno ili u kontejneru)
- RabbitMQ (lokalno ili u kontejneru)
- Redis (opcionalno; API ima Redis cache u konfiguraciji)
- Docker (opcionalno; za docker-compose setup)

## Konfiguracija

Konfiguracija je u `appsettings.json` fajlovima za svaki servis:

- REST API: `Backend/SecureGuard/SmartGuard.API/appsettings.json`
- Archive: `Backend/SecureGuard/SmartGuard.Archive.Microservice/appsettings.json`
- Notifications: `Backend/SecureGuard/SmartGuard.Notifications.Microservice/appsettings.json`

Važno:

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

Docker Compose se nalazi na:

- `Backend/SecureGuard/docker-compose.yml`

Compose koristi `.env` varijable (nije verzionisan). Kreiraj ga kopiranjem template-a:

```bash
cd Backend/SecureGuard
cp .env.example .env
```

Zatim upali sve servise:

```bash
docker compose --env-file .env up --build
```

Napomena: `docker-compose.yml` trenutno ne mapira portove za `smartguard.api` i `smartguard.archive.microservice` na host. Ako želiš pristup sa host mašine, napravi `docker-compose.override.yml` u istom folderu:

```yml
services:
  smartguard.api:
    ports:
      - "5000:8080"

  smartguard.archive.microservice:
    ports:
      - "5001:8080"
```

Infrastrukturni portovi (po defaultu):

- SQL Server: `localhost:1433`
- RabbitMQ: `localhost:5672`
- RabbitMQ management UI: `http://localhost:15672`
- Redis: `localhost:6379`

## Povezivanje sa klijentima

- Desktop app koristi `API_BASE_URL` i (po potrebi) `ARCHIVE_BASE_URL`: [Desktop/README.md](../Desktop/README.md)
- Mobile app koristi `API_BASE_URL`: [Mobile/README.md](../Mobile/README.md)
- ESP32 firmware treba da pokazuje na API (SignalR + REST) i upload endpoint: [ESP32/README.md](../ESP32/README.md)
