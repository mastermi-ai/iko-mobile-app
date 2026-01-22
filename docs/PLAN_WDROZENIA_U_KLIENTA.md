# 🚀 PLAN WDROŻENIA U KLIENTA

## Scenariusz: Wszystko na komputerze klienta z nexo PRO

**Data utworzenia:** 2026-01-22  
**Wersja:** 1.0

---

## 📋 PRZED SPOTKANIEM (Twoje przygotowanie)

### 1. Co musisz mieć ze sobą:
```
✅ Pendrive z plikami:
   ├── iko-cloud-api/          (cały folder projektu)
   ├── iko-nexo-bridge/        (cały folder projektu)
   ├── iko-mobile-app.apk      (zbudowana aplikacja)
   ├── docker-desktop-installer.exe  (opcjonalnie)
   └── ta-instrukcja.md
```

### 2. Zbuduj APK przed wyjazdem:
```bash
cd iko-mobile-app

# WAŻNE: Ustaw prawidłowy URL przed budowaniem!
# Edytuj lib/services/api_service.dart:
# static const String baseUrl = 'http://IP_KOMPUTERA_KLIENTA:3000';

flutter build apk --release
# Plik: build/app/outputs/flutter-apk/app-release.apk
```

### 3. Przygotuj plik konfiguracyjny dla klienta:
```bash
cp iko-nexo-bridge/appsettings.json iko-nexo-bridge/appsettings.template.json
```

---

## 📞 PRZED SPOTKANIEM (Pytania do klienta)

Zapytaj klienta przed wyjazdem:

| # | Pytanie | Dlaczego potrzebne |
|---|---------|-------------------|
| 1 | **Jaki system operacyjny?** | Windows 10/11? Server? |
| 2 | **Czy jest zainstalowany Docker?** | Jeśli nie - zainstalujemy |
| 3 | **Gdzie jest baza nexo PRO?** | Lokalnie czy na serwerze SQL? |
| 4 | **Nazwa serwera SQL i bazy** | Np. `localhost\NEXO` / `Nexo_Firma` |
| 5 | **Czy mają konto admina Windows?** | Do instalacji usług |
| 6 | **IP komputera w sieci LAN** | Do połączenia tabletów |
| 7 | **Ile handlowców?** | Do założenia kont |
| 8 | **Imiona i loginy handlowców** | Do konfiguracji |

---

## 🗓️ PLAN SPOTKANIA (krok po kroku)

### ETAP 1: Przygotowanie środowiska (30 min)

```
[ ] 1.1. Sprawdź wersję nexo PRO
    → Pomoc → O programie → Wersja: ____

[ ] 1.2. Zanotuj dane połączenia do bazy
    → Serwer SQL: ________________
    → Nazwa bazy: ________________
    → Login SQL (lub Windows Auth): ________________

[ ] 1.3. Zainstaluj Docker Desktop (jeśli brak)
    → Uruchom instalator
    → Restart komputera
    → Uruchom Docker Desktop

[ ] 1.4. Zainstaluj .NET 8.0 Runtime (jeśli brak)
    → https://dotnet.microsoft.com/download/dotnet/8.0
```

---

### ETAP 2: Instalacja Cloud API (45 min)

```
[ ] 2.1. Skopiuj folder iko-cloud-api na dysk C:
    C:\IKO\iko-cloud-api\

[ ] 2.2. Utwórz plik .env
```

Plik `C:\IKO\iko-cloud-api\.env`:
```env
DATABASE_URL="postgresql://iko_user:TajneHaslo123!@localhost:5432/iko_db"
JWT_SECRET="super-tajny-klucz-jwt-zmien-na-produkcji-min-32-znaki"
JWT_EXPIRATION="7d"
PORT=3000
```

```
[ ] 2.3. Uruchom Docker i bazę danych
    cd C:\IKO\iko-cloud-api
    docker-compose up -d

[ ] 2.4. Zainstaluj zależności i uruchom migrację
    npm install
    npx prisma migrate deploy
    npx prisma db seed

[ ] 2.5. Uruchom Cloud API
    npm run start:prod
    
    → Sprawdź: http://localhost:3000 (powinno zwrócić 404)
```

---

### ETAP 3: Konfiguracja Nexo Bridge (30 min)

```
[ ] 3.1. Skopiuj folder iko-nexo-bridge na dysk C:
    C:\IKO\iko-nexo-bridge\

[ ] 3.2. Skonfiguruj appsettings.json
```

Plik `C:\IKO\iko-nexo-bridge\appsettings.json`:
```json
{
  "NexoProSettings": {
    "ServerName": "NAZWA_SERWERA_SQL",
    "DatabaseName": "NAZWA_BAZY_NEXO",
    "Username": "",
    "Password": "",
    "OperatorSymbol": "ADMIN",
    "OperatorPassword": "haslo_operatora"
  },
  "CloudApiSettings": {
    "BaseUrl": "http://localhost:3000",
    "ApiKey": "bridge-secret-key"
  },
  "SyncSettings": {
    "SyncIntervalMinutes": 5,
    "OrderCheckIntervalSeconds": 30
  }
}
```

**Uzupełnij:**
- `ServerName` - nazwa serwera SQL (np. `localhost\SQLEXPRESS` lub `SERWER\NEXO`)
- `DatabaseName` - nazwa bazy nexo (np. `Nexo_Firma`)
- `OperatorPassword` - hasło operatora nexo

```
[ ] 3.3. Zbuduj aplikację
    cd C:\IKO\iko-nexo-bridge
    dotnet build -c Release

[ ] 3.4. Uruchom testowo
    dotnet run

    → Sprawdź logi: "Connected to nexo PRO"
```

---

### ETAP 4: Dodanie użytkowników (15 min)

```
[ ] 4.1. Dodaj handlowców przez API
```

W PowerShell:
```powershell
# Handlowiec 1
Invoke-RestMethod -Uri "http://localhost:3000/admin/users" -Method POST -ContentType "application/json" -Body '{"username": "handlowiec1", "password": "Haslo123!", "name": "Jan Kowalski", "clientId": 1}'

# Handlowiec 2
Invoke-RestMethod -Uri "http://localhost:3000/admin/users" -Method POST -ContentType "application/json" -Body '{"username": "handlowiec2", "password": "Haslo123!", "name": "Anna Nowak", "clientId": 1}'

# Handlowiec 3
Invoke-RestMethod -Uri "http://localhost:3000/admin/users" -Method POST -ContentType "application/json" -Body '{"username": "handlowiec3", "password": "Haslo123!", "name": "Piotr Wiśniewski", "clientId": 1}'

# Handlowiec 4
Invoke-RestMethod -Uri "http://localhost:3000/admin/users" -Method POST -ContentType "application/json" -Body '{"username": "handlowiec4", "password": "Haslo123!", "name": "Maria Kowalczyk", "clientId": 1}'
```

```
[ ] 4.2. Zapisz dane logowania dla handlowców
    
    | Handlowiec | Username | Hasło |
    |------------|----------|-------|
    | __________ | ________ | _____ |
    | __________ | ________ | _____ |
    | __________ | ________ | _____ |
    | __________ | ________ | _____ |
```

---

### ETAP 5: Synchronizacja danych z nexo (20 min)

```
[ ] 5.1. Uruchom pierwszą synchronizację produktów
    → Nexo Bridge automatycznie pobierze produkty
    → Sprawdź w przeglądarce: http://localhost:3000/sync/products

[ ] 5.2. Sprawdź czy produkty są w bazie
    → Powinno być > 0 produktów

[ ] 5.3. Sprawdź czy klienci są zsynchronizowani
    → http://localhost:3000/sync/customers
```

---

### ETAP 6: Konfiguracja sieci (15 min)

```
[ ] 6.1. Sprawdź IP komputera w sieci LAN
    ipconfig
    → IPv4 Address: _____________ (np. 192.168.1.100)

[ ] 6.2. Otwórz port 3000 w firewall Windows
    → Panel sterowania → Zapora Windows Defender
    → Reguły przychodzące → Nowa reguła
    → Port → TCP → 3000 → Zezwól na połączenie
    → Nazwa: "IKO Cloud API"

[ ] 6.3. Test z innego urządzenia w sieci
    → Na telefonie/tablecie otwórz: http://192.168.1.100:3000
    → Powinno zwrócić JSON z błędem 404 (to OK!)
```

---

### ETAP 7: Instalacja aplikacji na tablecie (15 min)

```
[ ] 7.1. Skopiuj APK na tablet (USB/email/pendrive)

[ ] 7.2. Zainstaluj aplikację na tablecie
    → Zezwól na instalację z nieznanych źródeł

[ ] 7.3. Zaloguj się na tablecie
    → Username: handlowiec1
    → Password: Haslo123!

[ ] 7.4. Zsynchronizuj dane
    → Pociągnij w dół na liście produktów
    → Sprawdź czy produkty się wczytały
```

⚠️ **WAŻNE:** APK musi być zbudowany z prawidłowym URL!

Przed wyjazdem do klienta edytuj `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://192.168.1.100:3000';  // IP komputera klienta
```

---

### ETAP 8: Instalacja jako usługa Windows (20 min)

#### 8.1 Cloud API jako usługa

Utwórz plik `C:\IKO\start-cloud-api.bat`:
```batch
@echo off
cd C:\IKO\iko-cloud-api
npm run start:prod
```

**Opcja A: Harmonogram zadań**
1. Otwórz "Harmonogram zadań"
2. Utwórz zadanie podstawowe
3. Wyzwalacz: "Przy uruchomieniu komputera"
4. Akcja: Uruchom program → `C:\IKO\start-cloud-api.bat`
5. Zaznacz: "Uruchom niezależnie od tego czy użytkownik jest zalogowany"

**Opcja B: NSSM (zalecane)**
```cmd
# Pobierz NSSM: https://nssm.cc/download
nssm install "IKO Cloud API" "C:\Program Files\nodejs\node.exe"
nssm set "IKO Cloud API" AppDirectory "C:\IKO\iko-cloud-api"
nssm set "IKO Cloud API" AppParameters "node_modules\.bin\nest start"
nssm start "IKO Cloud API"
```

#### 8.2 Nexo Bridge jako usługa Windows

W cmd jako Administrator:
```cmd
sc create "IKO Nexo Bridge" binPath="C:\IKO\iko-nexo-bridge\bin\Release\net8.0\IkoNexoBridge.exe" start=auto
sc description "IKO Nexo Bridge" "Synchronizacja IKO Mobile z InsERT nexo PRO"
sc start "IKO Nexo Bridge"
```

```
[ ] 8.3. Sprawdź czy usługi działają po restarcie
    → Uruchom ponownie komputer
    → Sprawdź: http://localhost:3000
    → Sprawdź: services.msc → "IKO Nexo Bridge"
```

---

### ETAP 9: Test końcowy (20 min)

```
[ ] 9.1. Test tworzenia zamówienia
    → Na tablecie: dodaj produkty do koszyka
    → Wybierz klienta
    → Utwórz zamówienie

[ ] 9.2. Sprawdź czy zamówienie dotarło do Cloud API
    → http://localhost:3000/orders

[ ] 9.3. Sprawdź czy zamówienie trafiło do nexo PRO
    → Otwórz nexo PRO
    → Handel → Dokumenty → Zamówienia od odbiorców (ZK)
    → Powinno być nowe zamówienie!

[ ] 9.4. Test offline
    → Wyłącz WiFi na tablecie
    → Utwórz zamówienie
    → Włącz WiFi
    → Sprawdź czy zamówienie się zsynchronizowało

[ ] 9.5. Test nowego klienta
    → Na tablecie: koszyk → "Nowy" klient
    → Wpisz NIP i dane
    → Utwórz zamówienie
    → Sprawdź w nexo: uwagi zamówienia zawierają dane klienta
```

---

## ✅ CHECKLIST PO WDROŻENIU

```
[ ] Cloud API działa na porcie 3000
[ ] Nexo Bridge łączy się z bazą nexo PRO
[ ] Produkty zsynchronizowane z nexo
[ ] Klienci zsynchronizowani z nexo
[ ] Handlowcy mogą się logować na tabletach
[ ] Zamówienia trafiają do nexo PRO jako ZK
[ ] Usługi uruchamiają się automatycznie po restarcie
[ ] Tablety połączone przez sieć LAN
[ ] Firewall przepuszcza port 3000
```

---

## 📞 DANE KONTAKTOWE (zostaw klientowi)

```
W razie problemów:
- Email: _______________
- Telefon: _______________

Typowe problemy i rozwiązania:

1. "Nie mogę się zalogować"
   → Sprawdź czy Cloud API działa: http://localhost:3000
   → Sprawdź czy hasło jest poprawne

2. "Brak produktów na tablecie"
   → Pociągnij w dół aby zsynchronizować
   → Sprawdź czy Nexo Bridge działa (services.msc)

3. "Zamówienie nie trafia do nexo"
   → Sprawdź usługę "IKO Nexo Bridge" w services.msc
   → Sprawdź logi w C:\IKO\iko-nexo-bridge\logs\

4. "Tablet nie łączy się z serwerem"
   → Sprawdź czy tablet jest w tej samej sieci WiFi
   → Sprawdź firewall (port 3000)
   → Ping IP serwera z tabletu
```

---

## ⏱️ SZACOWANY CZAS CAŁKOWITY

| Etap | Czas |
|------|------|
| Przygotowanie środowiska | 30 min |
| Cloud API | 45 min |
| Nexo Bridge | 30 min |
| Użytkownicy | 15 min |
| Synchronizacja | 20 min |
| Sieć | 15 min |
| Tablety | 15 min |
| Usługi Windows | 20 min |
| Testy | 20 min |
| **RAZEM** | **~3.5 godziny** |

**Bufor na problemy:** +1 godzina  
**Całkowity czas spotkania:** ~4.5 godziny

---

## 📁 STRUKTURA PLIKÓW U KLIENTA

Po wdrożeniu na komputerze klienta:

```
C:\IKO\
├── iko-cloud-api\
│   ├── .env                    ← konfiguracja bazy
│   ├── node_modules\
│   ├── prisma\
│   ├── src\
│   └── package.json
│
├── iko-nexo-bridge\
│   ├── appsettings.json        ← konfiguracja nexo
│   ├── bin\Release\net8.0\
│   │   └── IkoNexoBridge.exe   ← usługa Windows
│   └── logs\                   ← logi synchronizacji
│
└── start-cloud-api.bat         ← skrypt startowy
```

---

## 🔄 PROCEDURA AKTUALIZACJI

Gdy będzie nowa wersja aplikacji:

### Aktualizacja APK na tabletach:
1. Zbuduj nowy APK
2. Wyślij do handlowców
3. Zainstaluj (nadpisze starą wersję)

### Aktualizacja Cloud API:
```cmd
cd C:\IKO\iko-cloud-api
git pull origin main
npm install
npx prisma migrate deploy
# Restart usługi
```

### Aktualizacja Nexo Bridge:
```cmd
cd C:\IKO\iko-nexo-bridge
git pull origin main
dotnet build -c Release
# Restart usługi
sc stop "IKO Nexo Bridge"
sc start "IKO Nexo Bridge"
```

---

*Dokument wygenerowany automatycznie przez system IKO Mobile*
