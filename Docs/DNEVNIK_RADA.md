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
- Sinhronizovan razvoj spajanjem promjena iz udaljene grane (merge dev/master).

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
- Sinhronizovane promjene kroz više merge-ova grana (dev/master).

## 16.05.2026
- Implementirana kompletna funkcionalnost upravljanja poznatim osobama (known persons).
- Refaktorisana integracija known persons modula prema novim backend poljima i putanjama.
- Dodana migracija baze za face ID i brojač detekcija poznatih osoba.
- Sinhronizovan razvoj spajanjem promjena iz udaljene grane (merge dev/master).

## 17.05.2026
- Implementirane funkcionalnosti recordings modula.
- Dodano arhiviranje video snimaka, face alert notifikacije i cross-client autentikacija.
- Ispravljena logika refresh token-a i interceptor na mobilnoj aplikaciji.
- Provedena manja poboljšanja i ispravke vezane za known persons.
- Proširen backend i ESP32 firmware: validacija uređaja i opšte unapređenje API-ja.
- Uklonjeni/počišćeni referentni podaci (removed reference data).
- Implementirane postavke notifikacija za known persons (notification preferences).
- Ažuriran .gitignore.
- Sinhronizovane promjene kroz više merge-ova grana (dev/master).

## 18.05.2026
- Implementiran kompletan modul za upravljanje izvještajima (reports).
- Dodan sistem zakazanog generisanja PDF izvještaja (scheduled reporting).
- Implementiran audit logging sistem i kompletan modul audit logova.
- Refaktorisane postavke notifikacija korisnika i uklonjeni neiskorišteni AI rezultati analize.
- Proširen i uređen modul upozorenja (alerts).
- Sinhronizovan razvoj spajanjem promjena iz udaljene grane (merge dev/master).

## 19.05.2026
- Implementiran mobile dashboard (pregled ključnih metrika/stanja).
- Implementiran desktop dashboard.
- Dodan Redis caching i servisni sloj za dashboard podatke.
- Implementiran kompletan modul upravljanja alarmima (alarms management).
- Implementiran kompletan modul upravljanja alert-ovima (alerts) uz ažuriranje data modela.
- Ispravljena greška vezana za push notifikacije.
- Prilagođen app shell i bottom tab bar u mobilnoj aplikaciji.
- Uklonjeno nepotrebno pretraživanje (cleanup/refactor).
- Sinhronizovane promjene kroz više merge-ova grana (dev/master).
