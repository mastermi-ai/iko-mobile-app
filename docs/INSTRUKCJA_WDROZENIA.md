# 📱 IKO Mobile System - Instrukcja Wdrożenia u Klienta

## 🎯 Cel dokumentu

Ten dokument opisuje **krok po kroku** jak wdrożyć system IKO Mobile u klienta, który posiada InsERT nexo PRO.

---

## 📋 Wymagania przed wdrożeniem

### U klienta musi być:
- ✅ InsERT nexo PRO (wersja 30+)
- ✅ SQL Server (Express lub wyższy)
- ✅ Windows Server lub komputer Windows 10/11 (dla Nexo Bridge)
- ✅ Dostęp do internetu
- ✅ Tablety z Androidem dla handlowców

### Od nas:
- ✅ Cloud API (hostowane na serwerze)
- ✅ Aplikacja IKO Mobile (plik APK)
- ✅ Nexo Bridge (do zainstalowania u klienta)

---

## 🔄 Przepływ danych w systemie

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           U KLIENTA                                     │
│                                                                         │
│  ┌───────────────┐         ┌───────────────┐         ┌───────────────┐ │
│  │  nexo PRO     │◀───────▶│  Nexo Bridge  │◀───────▶│  Cloud API    │ │
│  │  (SQL Server) │ PRODUKTY│  (Win Service)│ INTERNET│  (serwer)     │ │
│  │               │ KLIENCI │               │         │               │ │
│  │  Zamówienia   │◀────────│  Zamówienia   │◀────────│  Zamówienia   │ │
│  └───────────────┘         └───────────────┘         └───────┬───────┘ │
│                                                              │         │
└──────────────────────────────────────────────────────────────┼─────────┘
                                                               │
                            ┌──────────────────────────────────┼─────────┐
                            │         W TERENIE                │         │
                            │                                  ▼         │
                            │  ┌───────────────┐    ┌───────────────┐   │
                            │  │ 📱 Tablet 1   │    │ 📱 Tablet 2   │   │
                            │  │ Handlowiec A  │    │ Handlowiec B  │   │
                            │  └───────────────┘    └───────────────┘   │
                            │                                            │
                            └────────────────────────────────────────────┘
```

---

## 🚀 Etapy wdrożenia

### ETAP 1: Przygotowanie Cloud API (1-2 godziny)

#### 1.1 Hostowanie API

**Opcja A - VPS (zalecana)**
```bash
# Na serwerze VPS (Ubuntu)
git clone https://github.com/mastermi-ai/iko-cloud-api.git
cd iko-cloud-api
docker-compose up -d
```

**Opcja B - Railway.app (szybka)**
- Wejdź na https://railway.app
- Połącz z repozytorium GitHub
- Railway automatycznie wdroży

#### 1.2 Konfiguracja .env

```env
DATABASE_URL="postgresql://user:password@host:5432/iko_db"
JWT_SECRET="wygeneruj-silny-klucz-jwt"
BRIDGE_API_KEY="wygeneruj-klucz-dla-nexo-bridge"
```

#### 1.3 Utworzenie konta klienta

```bash
# W Cloud API - uruchom seed lub dodaj ręcznie
npx prisma db seed
```

Lub przez API:
```bash
curl -X POST https://api.example.com/admin/clients \
  -H "Content-Type: application/json" \
  -d '{"companyName": "Nazwa Firmy Klienta", "nexoDbName": "NexoPRO"}'
```

---

### ETAP 2: Instalacja Nexo Bridge u klienta (2-3 godziny)

#### 2.1 Przygotowanie serwera

Na komputerze/serwerze klienta z dostępem do SQL Server nexo:

```powershell
# 1. Zainstaluj .NET 8.0 Runtime
# Pobierz z: https://dotnet.microsoft.com/download/dotnet/8.0

# 2. Pobierz Nexo Bridge
git clone https://github.com/mastermi-ai/iko-nexo-bridge.git
cd iko-nexo-bridge

# 3. Zbuduj
dotnet publish -c Release -o C:\IkoNexoBridge
```

#### 2.2 Konfiguracja połączenia

Edytuj `C:\IkoNexoBridge\appsettings.json`:

```json
{
  "CloudApi": {
    "BaseUrl": "https://api.twoja-domena.pl",
    "ApiKey": "KLUCZ-API-OD-NAS",
    "ClientId": 1
  },
  "NexoPro": {
    "ServerName": "SERWER-KLIENTA\\NEXO",
    "DatabaseName": "NexoPRO_FirmaKlienta",
    "Username": "",
    "Password": ""
  }
}
```

**Jak znaleźć dane nexo u klienta:**

1. **Nazwa serwera SQL**: 
   - Otwórz nexo PRO → Pomoc → O programie → zakładka "Baza danych"
   - Lub uruchom SQL Server Configuration Manager

2. **Nazwa bazy danych**:
   - W nexo: Narzędzia → Opcje → Baza danych
   - Lub w SQL Management Studio - lista baz

#### 2.3 Test połączenia

```powershell
cd C:\IkoNexoBridge
dotnet IkoNexoBridge.dll
```

Powinno wyświetlić:
```
info: Connecting to nexo PRO: SERWER\NEXO/NexoPRO
info: Successfully connected to nexo PRO database via SQL
info: IKO Nexo Bridge Worker starting...
```

#### 2.4 Instalacja jako Windows Service

```powershell
# Jako Administrator
sc.exe create "IkoNexoBridge" binPath="C:\IkoNexoBridge\IkoNexoBridge.exe" start=auto
sc.exe start IkoNexoBridge
```

---

### ETAP 3: Pierwsza synchronizacja (30 minut)

#### 3.1 Synchronizacja produktów

Po uruchomieniu Nexo Bridge automatycznie:
1. Pobierze produkty z nexo PRO
2. Wyśle je do Cloud API
3. Aplikacje mobilne pobiorą produkty przy synchronizacji

**Sprawdzenie:**
```powershell
# Logi Nexo Bridge
Get-Content C:\IkoNexoBridge\logs\*.log -Tail 20

# Powinno pokazać:
# info: Fetching products from nexo PRO
# info: Fetched 1234 products from nexo PRO
# info: Successfully synced 1234 products to Cloud API
```

#### 3.2 Synchronizacja kontrahentów

Analogicznie jak produkty - automatyczna synchronizacja.

---

### ETAP 4: Konfiguracja tabletów (15 min/tablet)

#### 4.1 Instalacja APK

1. Prześlij `IKO-vX.apk` na tablet (email, pendrive, Google Drive)
2. Na tablecie: Ustawienia → Zabezpieczenia → włącz "Nieznane źródła"
3. Otwórz plik APK → Zainstaluj

#### 4.2 Konfiguracja aplikacji

Przed wydaniem APK klientowi, upewnij się że w kodzie:
```dart
// lib/services/api_service.dart
static const String baseUrl = 'https://api.twoja-domena.pl';
```

#### 4.3 Utworzenie kont handlowców

W Cloud API lub przez panel administracyjny:
```bash
# Dodaj handlowca
curl -X POST https://api.example.com/admin/salesmen \
  -H "Content-Type: application/json" \
  -d '{
    "username": "jan_kowalski",
    "password": "silne_haslo_123",
    "name": "Jan Kowalski",
    "clientId": 1
  }'
```

#### 4.4 Test logowania

Na tablecie:
1. Otwórz aplikację IKO
2. Wpisz login i hasło handlowca
3. Kliknij "Zaloguj się"

---

### ETAP 5: Test całego przepływu (1 godzina)

#### 5.1 Test: Produkty z nexo → tablet

1. W nexo PRO dodaj testowy produkt
2. Poczekaj na synchronizację (max 60 min) lub wymuś:
   - Zrestartuj Nexo Bridge
3. Na tablecie: Kliknij "Sync" → Produkty
4. Sprawdź czy nowy produkt jest widoczny

#### 5.2 Test: Zamówienie z tabletu → nexo

1. Na tablecie:
   - Wybierz klienta
   - Dodaj produkty do koszyka
   - Złóż zamówienie
2. W Nexo Bridge:
   - Sprawdź logi - powinno pokazać przetwarzanie zamówienia
3. W nexo PRO:
   - Dokumenty → Zamówienia od odbiorców
   - Sprawdź czy jest nowe ZO

---

## 📊 Mapowanie danych nexo ↔ IKO

### Produkty (tw__Towar → Product)

| nexo PRO | Cloud API | Aplikacja |
|----------|-----------|-----------|
| tw_Symbol | code | Kod produktu |
| tw_Nazwa | name | Nazwa |
| ce_WartoscNetto | priceNetto | Cena netto |
| ce_WartoscBrutto | priceBrutto | Cena brutto |
| sv_Stawka | vatRate | Stawka VAT |
| jm_Symbol | unit | Jednostka |

### Kontrahenci (kh__Kontrahent → Customer)

| nexo PRO | Cloud API | Aplikacja |
|----------|-----------|-----------|
| kh_Nazwa | name | Nazwa |
| kh_NazwaSkrocona | shortName | Nazwa skrócona |
| adr_Ulica | address | Adres |
| adr_Miejscowosc | city | Miasto |
| kh_NIP | nip | NIP |

### Zamówienia (Order → Dokument ZO)

| Aplikacja | Cloud API | nexo PRO |
|-----------|-----------|----------|
| Data zamówienia | orderDate | DataWystawienia |
| Kontrahent | customerId | Kontrahent |
| Pozycje | items | Pozycje dokumentu |
| Uwagi | notes | Uwagi |

---

## 🔧 Konserwacja i wsparcie

### Codzienne sprawdzanie

```powershell
# Status serwisu
sc.exe query IkoNexoBridge

# Ostatnie logi
Get-Content C:\IkoNexoBridge\logs\*.log -Tail 50
```

### Restart po problemach

```powershell
sc.exe stop IkoNexoBridge
sc.exe start IkoNexoBridge
```

### Aktualizacja Nexo Bridge

```powershell
sc.exe stop IkoNexoBridge
# Podmień pliki w C:\IkoNexoBridge
sc.exe start IkoNexoBridge
```

---

## ❓ FAQ

### P: Jak często synchronizują się dane?
**O:** Domyślnie co 60 minut dla produktów i klientów. Zamówienia są przetwarzane co 30 sekund.

### P: Czy handlowiec może pracować offline?
**O:** Tak! Produkty i klienci są zapisani lokalnie. Zamówienia też zapisują się offline i synchronizują gdy jest internet.

### P: Co się stanie jak nexo będzie niedostępne?
**O:** Nexo Bridge będzie próbował połączyć się ponownie co 30 sekund. Zamówienia poczekają w Cloud API.

### P: Czy można mieć kilku handlowców?
**O:** Tak, każdy handlowiec ma osobne konto i może używać osobnego tabletu.

---

## 📞 Kontakt

**Wsparcie techniczne:** support@prodaut.pl
**Dokumentacja:** https://github.com/mastermi-ai/iko-mobile-app

---

*Wersja dokumentu: 1.0*
*Data: Styczeń 2026*
*© PRODAUT*
