<div align="center">

<!-- LOGO PROJEKTA -->
<img src="https://i.imgur.com/N9LNlam.png" alt="SmartGuard Logo" height="200" style="border-radius: 20px;" />

# 🛡️ SmartGuard

### _Open-Source IoT Sigurnosni Sistem_

> **Vaša kuća. Vaša kontrola. Vaši podaci.**

[![Licenca](https://img.shields.io/badge/Licenca-Open%20Source-blue?style=for-the-badge)](LICENSE)
[![Platforma](https://img.shields.io/badge/Platforma-.NET%20%7C%20Flutter%20%7C%20ESP32-purple?style=for-the-badge)](https://github.com/DusanPeric44/SmartGuard)
[![Backend](https://img.shields.io/badge/Backend-.NET%2010.0-512BD4?style=for-the-badge&logo=dotnet)](Backend/README.md)
[![Mobile](https://img.shields.io/badge/Mobilna-Flutter-02569B?style=for-the-badge&logo=flutter)](Mobile/README.md)

---

</div>

## 📖 O projektu

**SmartGuard** je **_self-hosted IoT sigurnosno rješenje_** za pametne domove koje kombinuje:

- 📷 **ESP32-CAM edge uređaje** za lokalno snimanje i baferovanje videa
- ⚙️ **.NET Backend** (REST + SignalR) za real-time komunikaciju i poslovnu logiku
- 📱 **Flutter mobilnu/desktop aplikaciju** za upravljanje i praćenje

Osnovna filozofija projekta počiva na tri stuba:

|                      🔒 Privatnost                      |        💾 Minimalni Storage         |              ⚡ Real-Time               |
| :-----------------------------------------------------: | :---------------------------------: | :-------------------------------------: |
| Podaci ostaju kod korisnika — bez cloud-a trećih strana | Event-driven snimanje + ring buffer | Live stream + instant push notifikacije |

---

## 🔗 Brzi linkovi

| Komponenta       | Opis                                 | Link                                   |
| ---------------- | ------------------------------------ | -------------------------------------- |
| 🖥️ **Backend**   | .NET mikroservisi, REST API, SignalR | [Backend/README.md](../Backend/README.md) |
| 📡 **ESP32-CAM** | Firmware i Wi-Fi provisioning        | [ESP32/README.md](../ESP32/README.md)     |
| 📱 **Mobilna**   | Flutter Android aplikacija           | [Mobile/README.md](../Mobile/README.md)   |
| 🖱️ **Desktop**   | Flutter admin panel                  | [Desktop/README.md](../Desktop/README.md) |

---

## ❗ Problem koji rješavamo

Klasična "pametna" kućna sigurnost često donosi ozbiljne nedostatke:

- 💸 **Mjesečne pretplate za cloud storage**
- 🕵️ **Nejasne politike obrade lica i snimaka**
- 🔐 **Vendor lock-in** — ako servis prestane s radom, nestaje i sigurnost
- 📼 **Nepotrebno 24/7 snimanje videa** koje troši prostor i propusnost

> **_SmartGuard pristup je suprotan:_ lokalna kontrola + minimalni podaci + otvoreni kod.**

---

## ✨ Ključne karakteristike

### 🎥 Live Stream bez latencije

ESP32 šalje JPEG frame-ove backendu, koji ih putem SignalR-a prosljeđuje klijentima u realnom vremenu.

### 📅 Event-driven snimanje

Snimci i arhive nastaju samo kada se desi relevantan događaj — _detektovan pokret_, _prepoznato lice_ ili _aktiviran alarm_ — umjesto stalnog snimanja.

### 🔁 Ring buffer na SD kartici

Uređaj čuva ograničen broj "normalnih" snimaka na SD kartici, dok event snimke tretira kao prioritetne klipove.

### 👤 Detekcija lica i poznate osobe

Događaji prepoznavanja lica se povezuju s registrovanim "poznatim osobama", uz mogućnost postavljanja selektivnih notifikacija po osobi.

### 🔔 Selektivne notifikacije

Push/email obavijesti samo za tipove događaja i osobe _koje vi odaberete_.

### 🔑 Sigurnost i autorizacija

JWT autentifikacija, role-based autorizacija (**Admin** / **HomeOwner** / **Viewer**), audit trail i soft delete.

### 📈 Skalabilnost

Podrška za više ESP32 uređaja uz asinhroničnu obradu putem message brokera.

---

## 🏗️ Pregled arhitekture

SmartGuard je dizajniran kao skup komponenti s jasnom podjelom između real-time streaminga, poslovne logike i zahtjevnih pozadinskih operacija.

<!-- 📌 PLACEHOLDER ZA SLIKU: Zamijenite dijagramom arhitekture -->

> **[ OVDJE UMETNUTI DIJAGRAM ARHITEKTURE ]**
> _(npr. dijagram koji prikazuje ESP32 → REST API → SignalR → Flutter klijenti)_

### Pregled komponenti

| Komponenta                        | Uloga                                                                                                  |
| --------------------------------- | ------------------------------------------------------------------------------------------------------ |
| 📡 **ESP32-CAM (Edge)**           | Lokalno snimanje i ring buffer; upload frame-ova i event snimaka; Wi-Fi provisioning                   |
| 🖥️ **REST API (.NET)**            | Auth/AuthZ; CRUD (uređaji, snimci, alarmi, poznate osobe); SignalR hubovi; objavljuje poruke workerima |
| 📬 **Notification Worker (.NET)** | Konzumira poruke → šalje email + push (FCM)                                                            |
| 📦 **Archiving Worker (.NET)**    | Preuzima MJPEG snimke s uređaja; čuva na serveru; ažurira statuse snimaka                              |
| 🗄️ **SQL Server**                 | Centralna relaciona baza (domenski entiteti + referentne tabele)                                       |
| 🐇 **RabbitMQ**                   | Asinhroni tokovi poruka (notifikacije i arhiviranje)                                                   |
| 📱 **Flutter Mobile**             | Korisnička aplikacija — live prikaz, snimci, alarmi, poznate osobe, notifikacije                       |
| 🖱️ **Flutter Desktop**            | Admin panel — upravljanje sistemom, izvještaji, audit logovi                                           |

---

## 🔄 Tokovi podataka

### 📡 Live Stream

```
ESP32  →  REST API (upload frame-a)  →  SignalR Hub  →  Mobilni / Desktop klijent
```

### 🎬 Event snimak

```
ESP32 najavljuje upload  →  API objavljuje poruku  →  Archiving Worker preuzima snimak
  →  Čuva na storage-u  →  API ažurira status snimka
```

### 🔔 Notifikacije

```
API objavljuje poruku  →  Notification Worker šalje Email / Push
  →  SignalR in-app notifikacije
```

---

## 💡 Inovativnost

| 🧩 Karakteristika                   | Opis                                                                                          |
| ----------------------------------- | --------------------------------------------------------------------------------------------- |
| 🔀 **Hibridni Edge + Server**       | Obrada je podijeljena između uređaja (edge) i backenda s jasnim granicama privatnosti         |
| 📉 **Minimalni podaci po defaultu** | Snimaju se samo relevantni događaji; ring buffer služi kao sigurnosna mreža                   |
| 🔓 **Open-Source i auditabilan**    | Svako može pregledati kompletan tok podataka i sigurnosne odluke (auth, audit, state machine) |
| 📡 **Real-Time bez cloud lock-ina** | SignalR push tokovi — bez posredničkih servisa ili pretplata                                  |

---

## 🌍 Utjecaj na okruženje

- 🏠 **Privatnost kao default** — podaci ostaju u lokalnoj infrastrukturi (kuća ili firma), a ne kod trećih strana
- 💰 **Budžetski pristupačno** — ESP32-CAM uređaji omogućavaju jeftino skaliranje (više kamera bez povećanja pretplate)
- 🏢 **Primjenjivo u praksi** — kuće, mali biznisi (prodavnice/restorani), apartmanski kompleksi (više korisnika, više nivoa pristupa)

---

## 🛠️ Tehnička realizacija

### 📦 Gotova rješenja (building blocks)

Etablirani alati i frameworki korišteni kao osnova:

- **Hardver:** ESP32-CAM + SD kartica
- **Frameworki:** .NET (`net10.0`), Flutter, SignalR, Entity Framework Core
- **Infrastruktura:** SQL Server, RabbitMQ (message broker)

### ✍️ Autorski rad tima

Sve ispod je izradio SmartGuard tim:

- 🗃️ **Modeliranje domene i baze** — entiteti, relacije, soft delete, audit
- ⚙️ **Backend poslovna logika** — state machine za alarme/snimke, ownership provjere, API key autentifikacija za uređaje
- 📡 **Real-Time tokovi** — SignalR hubovi + provjera prava pristupa na stream
- 🔧 **Worker servisi** — queue potrošači, retry logika, slanje email/push, arhiviranje i struktura storage-a
- 📱 **Flutter klijenti** — UI, navigacija, auth tokovi, filteri/paginacija, master-detail ekrani, PDF izvještaji (desktop)
- 📡 **ESP32 firmware tok** — provisioning, slanje događaja, lokalni buffer i retry sinhronizacije

---

## 📁 Struktura repozitorija

```
SmartGuard/
├── 📂 Backend/     # .NET API + mikroservisi + domenski model
├── 📂 ESP32/       # Firmware za ESP32-CAM + provisioning
├── 📂 Mobile/      # Flutter Android aplikacija
├── 📂 Desktop/     # Flutter desktop admin aplikacija
└── 📂 Docs/        # Dokumentacija za prijavu i takmičenje
```

> Detaljni opisi i upute za pokretanje svake komponente nalaze se u `README.md` fajlovima iz sekcije **Brzi linkovi** iznad.

---

## 🚀 Pokretanje sistema (end-to-end)

### ✅ Preduvjeti

Za kompletan demo potrebno je:

| Zahtjev                 | Napomena                             |
| ----------------------- | ------------------------------------ |
| 🗄️ SQL Server           | Centralna baza podataka              |
| 🐇 RabbitMQ             | Queue za worker servise              |
| 🔴 Redis _(opcionalno)_ | Cache, ovisno o konfiguraciji API-ja |
| 🔷 .NET SDK `net10.0`   | Za lokalno pokretanje servisa        |
| 🐦 Flutter SDK          | Za pokretanje klijenata              |

---

### 🐳 Opcija A: Docker _(Preporučeno)_

Docker Compose konfiguracija se nalazi na:

```
Backend/SecureGuard/docker-compose.yml
```

Pokretanjem Compose-a pokreću se:

| Servis                                  | Opis                     |
| --------------------------------------- | ------------------------ |
| `smartguard.api`                        | REST API + SignalR       |
| `smartguard.archive.microservice`       | Archiving worker         |
| `smartguard.notifications.microservice` | Notification worker      |
| `sqlserver`                             | SQL Server 2022          |
| `rabbitmq`                              | RabbitMQ + management UI |
| `redis`                                 | Redis cache              |

> ⚠️ Potreban je `.env` fajl sa sljedećim varijablama: `SQLSERVER_SA_PASSWORD`, `RABBITMQ_USER`, `RABBITMQ_PASSWORD`, `REDIS_PASSWORD`

**Pokretanje sistema iz root-a repozitorija:**

```bash
docker compose -f Backend/SecureGuard/docker-compose.yml --env-file Backend/SecureGuard/.env up --build
```

Za mapiranje portova (npr. `localhost:5000`, `localhost:5001`), pogledajte [Backend/README.md](Backend/README.md).

---

### 💻 Opcija B: Lokalno (bez Dockera)

**Korak 1 — Pokretanje infrastrukture:**

```bash
# Pokreni SQL Server i kreiraj bazu
# Naziv baze: SmartGuardDb
# (connection string se nalazi u backend konfiguraciji)

# Pokreni RabbitMQ (default: guest/guest)
# Pokreni Redis (opcionalno)
```

**Korak 2 — Pokretanje .NET servisa** _(detalji u [Backend/README.md](Backend/README.md))_:

- REST API
- Archiving Worker
- Notifications Worker

**Korak 3 — Pokretanje Flutter klijenata:**

- 📱 Mobilna → [Mobile/README.md](Mobile/README.md)
- 🖱️ Desktop → [Desktop/README.md](Desktop/README.md)

**Korak 4 — Flash i provisioning ESP32-a** → [ESP32/README.md](ESP32/README.md)

---

## 📸 Screenshot-ovi

<!-- 📌 PLACEHOLDER ZA SLIKE: Zamijenite stvarnim screenshot-ovima aplikacije -->

|        Mobilna aplikacija         |           Desktop Admin            |           Live Stream prikaz           |
| :-------------------------------: | :--------------------------------: | :------------------------------------: |
| _[ UMETNUTI SCREENSHOT MOBILNE ]_ | _[ UMETNUTI SCREENSHOT DESKTOPA ]_ | _[ UMETNUTI SCREENSHOT LIVE PRIKAZA ]_ |

---

## 👥 Tim

| Ime                       | ID       |
| ------------------------- | -------- |
| 👨‍💻 **Dušan Perić**        | IB230222 |
| 👨‍💻 **Marko Milidragović** | IB230221 |

---

<div align="center">

[![GitHub](https://img.shields.io/badge/GitHub-DusanPeric44%2FSmartGuard-181717?style=for-the-badge&logo=github)](https://github.com/DusanPeric44/SmartGuard)

</div>
