# Dnevnik projekta

## 23.04.2026

- Inicijalizovan projekat i postavljena početna struktura repozitorijuma.

## 28.04.2026

- Kreiran kostur backend aplikacije (osnovna arhitektura i inicijalna konfiguracija).

## 29.04.2026

- Postavljena početna struktura Flutter mobilne aplikacije sa core modulima.
- Skafoldovana Flutter desktop aplikacija sa autentikacijom, rutiranjem i core modulima.

## 05.05.2026

- Implementirana autentikacija, mikroservisna organizacija i podrška za soft delete.

## 06.05.2026

- Implementiran RBAC (role-based access control) i uveden repository sloj.
- Proširena autentikacija i dodani početni ekrani/moduli: dashboard, uređaji, permisije, recordings i referentni podaci.
- Dodani stub podaci radi bržeg testiranja funkcionalnosti.
- Ažurirana dokumentacija i dodan dokument za RS2 entry.

## 09.05.2026

- Implementirana infrastruktura za real-time streaming i mrežnu komunikaciju.
- Dodane funkcionalnosti profila, uređaja, te login i registracije.

## 10.05.2026

- Ispravljeni problemi vezani za autentikaciju.

## 11.05.2026

- Dodan sistem registracije ESP32 kamere i implementiran streaming mehanizam.

## 15.05.2026

- Implementirana kompletna funkcionalnost upravljanja korisnicima (manage-users).
- Dodana podrška za push notifikacije i lokalne notifikacije; provedena dodatna podešavanja notifikacija.
- Ažurirani algoritmi/komponente za face detection i prateći ESP32 dio.
- Prilagođeni moduli uređaja i live-stream-a novom backend API-ju.
- Proširena podrška za ESP32 uređaje i dodani prateći backend endpointi (npr. device details).
- Refaktorisano korištenje email-a kao identifikatora za device korisnike.
- Ispravljeno ograničenje aplikacije na admin-only, popravljeni API dijelovi i urađeno čišćenje koda.
- Provedena migracija na Dio (HTTP klijent) i usklađivanje mrežnog sloja.

## 16.05.2026

- Implementirana kompletna funkcionalnost upravljanja poznatim osobama (known persons).
- Refaktorisana integracija known persons modula prema novim backend poljima i putanjama.
- Dodana migracija baze za face ID i brojač detekcija poznatih osoba.

## 17.05.2026

- Implementirane funkcionalnosti recordings modula.
- Dodano arhiviranje video snimaka, face alert notifikacije i cross-client autentikacija.
- Ispravljena logika refresh token-a i interceptor na mobilnoj aplikaciji.
- Provedena manja poboljšanja i ispravke vezane za known persons.
- Proširen backend i ESP32 firmware: validacija uređaja i opšte unapređenje API-ja.
- Uklonjeni/počišćeni referentni podaci (removed reference data).
- Implementirane postavke notifikacija za known persons (notification preferences).

## 18.05.2026

- Implementiran kompletan modul za upravljanje izvještajima (reports).
- Dodan sistem zakazanog generisanja PDF izvještaja (scheduled reporting).
- Implementiran audit logging sistem i kompletan modul audit logova.
- Refaktorisane postavke notifikacija korisnika i uklonjeni neiskorišteni AI rezultati analize.
- Proširen i uređen modul upozorenja (alerts).

## 19.05.2026

- Implementiran mobile dashboard (pregled ključnih metrika/stanja).
- Implementiran desktop dashboard.
- Dodan Redis caching i servisni sloj za dashboard podatke.
- Implementiran kompletan modul upravljanja alarmima (alarms management).
- Implementiran kompletan modul upravljanja alert-ovima (alerts) uz ažuriranje data modela.
- Ispravljena greška vezana za push notifikacije.
- Prilagođen app shell i bottom tab bar u mobilnoj aplikaciji.
- Uklonjeno nepotrebno pretraživanje (cleanup/refactor).

## 20.05.2026

- Implementiran modul arhive snimaka (recording archive) u mobilnoj aplikaciji.
- Ažuriran profil korisnika u mobilnoj aplikaciji.
- Ispravljeno odjavljivanje (logout) i čišćenje lokalno sačuvanih informacija.
- Ispravljena greška u desktop aplikaciji vezana za error builder.

## 22.05.2026

- Implementiran status uređaja (device status).

## 24.05.2026

- Implementirana Google autentikacija (OAuth) i desktop sign-in flow.
- Proširena funkcionalnost arhiviranja snimaka i dodana podrška za ESP32 flash procese.

## 25.05.2026

- Ažuriran SmartGuard stack kroz sve slojeve aplikacije.
- Implementirana tamna tema u mobilnoj aplikaciji.
- Provedeno čišćenje i refaktor dashboard-a.
- Ispravljeni problemi statusa uređaja i prikaza "last seen".
- Uređen prikaz uređaja (uklonjeni nepotrebni podaci i ispravljeni problemi prikaza email-a).
- Provedena optimizacija performansi i UI poboljšanja (npr. collapse ikonice).
- Uklonjeni osjetljivi fajlovi i informacije iz repozitorijuma.

## 26.05.2026

- Unaprijeđena pouzdanost slanja push notifikacija dodavanjem try/catch mehanizma za FCM poruke.

## 27.05.2026

- Dodana podrška za snimanje stream-a kamere, upload arhive i recording events u live stream modulu.
- Implementiran video player i ograničeno preuzimanje snimaka za viewer uloge.
- Dodana podrška za više tipova snimaka (multiple recording types).
- Stabilizovan proces stream-a i snimanja (ažuriranje record dugmeta i pojednostavljen state).
- Ažurirani algoritmi za prepoznavanje lica: vector matching, face detection unapređenja, centroid i normalizacija embedding-a.
- Usklađene UTC datumske vrijednosti.
- Ispravljeni problemi na ekranima uređaja (refresh, uklonjen storage capacity) i popravljeni servisni dijelovi vezani za access sinhronizaciju.
- Ažurirani nazivi i ikone mobilne i desktop aplikacije.

## 28.05.2026

- Implementirano spajanje/kombinovanje poznatih osoba (known persons merge/combine) i dodan drag & drop.
- Dodana funkcionalnost promjene naziva uređaja (device rename).
- Implementiran kompletan real-time sistem notifikacija.
- Automatizovan upis UserNotificationPreference i refaktorisana logika notifikacionih preferenci uz čišćenje koda.
- Stabilizovan streaming i face recognition mehanizam.
- Ispravljeni UI problemi na uređajima (loader, refresh na klik) i poboljšana pretraga (terminacija search term-a).

## 29.05.2026

- Uklonjeno polje lokacije iz modula poznatih osoba (removed location known persons).

