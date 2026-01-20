# 📊 RAPORT FUNKCJONALNY I AUDYT LOGICZNY
## Aplikacja Mobilna SFA (Sales Force Automation) - IKO

**Data analizy:** Styczeń 2026
**Wersja dokumentu:** 1.1

---

## ⚠️ KONTEKST ANALIZY

> **WAŻNE:** Ten raport został stworzony na podstawie analizy **STAREJ, niedziałającej już aplikacji klienta (POSDI.apk)**, która znajduje się w folderze `baza/`.
>
> **Cel analizy:** Reverse engineering starej aplikacji posłużył jako **wzorzec funkcjonalny** do stworzenia nowej aplikacji **IKO Mobile** (Flutter).
>
> **Screenshoty:** Zrzuty ekranu (Unknown-*.jpg) w folderze `baza/` pochodzą ze starej aplikacji POSDI i pokazują **oryginalny wygląd UI**, który odtwarzamy w nowej aplikacji.

---

**Analizowane materiały (WZORZEC):**
- Zrzuty ekranu UI starej aplikacji (9 screenów z folderu `baza/`)
- Zdekompilowana stara aplikacja `baza/POSDI.apk`
- Definicje API z kodu smali (reverse engineering)
- Struktury baz danych SQLite starej aplikacji

**Rezultat analizy:**
- Nowa aplikacja **IKO Mobile** (Flutter) - reimplementacja z modernizacją
- Nowe **Cloud API** (NestJS) - zamiast starego serwera POSDI
- Nowy **Nexo Bridge** (.NET) - integracja z InsERT nexo PRO (zamiast WAPRO)

---

## 1. 🔍 ANALIZA LOGIKI BIZNESOWEJ (Reverse Engineering)

### 1.1 User Story - Główny Przepływ Handlowca

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PRZEPŁYW GŁÓWNY                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. LOGOWANIE                                                               │
│     ├── Użytkownik: login + hasło                                          │
│     ├── API: POST /api_android/login                                       │
│     └── Rezultat: Token sesji, synchronizacja konfiguracji                 │
│                                                                             │
│  2. DASHBOARD (po zalogowaniu)                                             │
│     ├── Widoczny: Nazwa handlowca (np. "BOGDAN KRÓL (2)")                  │
│     ├── Moduły: Produkty, Klienci, Zamówienia, Oferty, Koszyk, Schowki     │
│     └── Akcje: Wyszukiwanie globalne (ikona lupy), Synchronizacja          │
│                                                                             │
│  3. WYBÓR KLIENTA (opcjonalnie)                                            │
│     ├── Lista klientów z: nazwą, adresem, NIP, telefonem                   │
│     ├── Akcja: "Pracuj z klientem" → ustawia kontekst                      │
│     └── Alternatywa: "Pracuj bez klienta"                                  │
│                                                                             │
│  4. PRZEGLĄDANIE PRODUKTÓW                                                 │
│     ├── Lista produktów z: kodem, nazwą, ceną, jednostką, zdjęciem         │
│     ├── Wyszukiwanie: po nazwie, kodzie kreskowym, głosowo                 │
│     ├── Filtrowanie: promocje                                              │
│     └── Prezentacja: tryb slajdów dla klienta                              │
│                                                                             │
│  5. DODAWANIE DO KOSZYKA                                                   │
│     ├── Ilość podstawowa + Gratis (ilość dodatkowa)                        │
│     ├── Możliwość zmiany ceny (cart_user_netto)                            │
│     ├── Komentarz do pozycji                                               │
│     └── Rabaty: automatyczne (z klienta) lub ręczne                        │
│                                                                             │
│  6. FINALIZACJA ZAMÓWIENIA                                                 │
│     ├── Przegląd koszyka z podsumowaniem                                   │
│     ├── Wybór: Zamówienie lub Oferta                                       │
│     ├── Uwagi do dokumentu                                                 │
│     └── Zapis lokalny + próba wysyłki do API                               │
│                                                                             │
│  7. SYNCHRONIZACJA → ERP                                                   │
│     ├── Automatyczna: co 15 minut (DATA_SYNC_INTERVAL)                     │
│     ├── Ręczna: przycisk "Synchronizuj"                                    │
│     └── Batch sync: wszystkie zmiany jednym requestem                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Kluczowe Obiekty i Atrybuty (z API)

#### 📦 PRODUKT (products)

| Pole w API | Opis | Mapowanie na nexo PRO |
|------------|------|----------------------|
| `products_id` | Unikalny identyfikator | `Towar.Id` |
| `products_name` | Nazwa produktu | `Towar.Nazwa` |
| `products_wapro_name` | Nazwa z ERP | `Towar.Nazwa` (źródło) |
| `products_ean` | Kod kreskowy EAN | `Towar.EAN` |
| `products_price_netto` | Cena netto bazowa | `Towar.CenaDetaliczna` |
| `products_price_brutto` | Cena brutto | `Towar.CenaBruttoDetaliczna` |
| `products_unit` | Jednostka miary | `Towar.JednostkaMiary.Symbol` |
| `products_vat` | Stawka VAT | `Towar.StawkaVat.Stawka` |
| `products_promo_netto` | Cena promocyjna netto | Cennik specjalny |
| `products_promo_brutto` | Cena promocyjna brutto | Cennik specjalny |
| `products_promo_from` | Data rozpoczęcia promocji | Atrybut własny |
| `products_promo_to` | Data zakończenia promocji | Atrybut własny |
| `products_promo_discount` | % rabatu promocyjnego | Atrybut własny |
| `products_available_volume` | Stan magazynowy | `Towar.StanMagazynu` |
| `products_image_url` | URL zdjęcia | System plików |
| `products_params` | Parametry techniczne | Atrybuty własne |
| `products_info` | Opis produktu | `Towar.Opis` |

#### 👤 KLIENT (customers)

| Pole w API | Opis | Mapowanie na nexo PRO |
|------------|------|----------------------|
| `customers_id` | Unikalny identyfikator | `Kontrahent.Id` |
| `local_id` | ID lokalne (offline) | Wewnętrzne |
| `customers_company_name` | Pełna nazwa firmy | `Kontrahent.Nazwa` |
| `customers_company_shortname` | Nazwa skrócona | `Kontrahent.NazwaSkrocona` |
| `customers_contact_email1` | Email kontaktowy | `Kontrahent.Email` |
| `customers_discount1` | Rabat stały 1 | `Kontrahent.Rabat` (?) |
| `customers_discount2` | Rabat stały 2 | Atrybut własny |
| `customers_wapro_groups_id` | Grupa cenowa | `Kontrahent.GrupaCenowa.Id` |
| `customers_wapro_prices_id` | Cennik indywidualny | Cennik własny |
| `customers_wapro_payer_id` | Płatnik nadrzędny | `Kontrahent.Platnik.Id` |
| `customers_nip` | NIP | `Kontrahent.NIP` |
| `customers_regon` | REGON | `Kontrahent.REGON` |
| `customers_city` | Miasto | `Kontrahent.Adres.Miejscowosc` |
| `customers_street` | Ulica | `Kontrahent.Adres.Ulica` |
| `customers_province` | Województwo | `Kontrahent.Adres.Wojewodztwo` |
| `customers_contact_name` | Imię osoby kontaktowej | `Kontrahent.OsobaKontaktowa` |
| `customers_contact_last_name` | Nazwisko os. kontaktowej | `Kontrahent.OsobaKontaktowa` |

#### 🧾 ZAMÓWIENIE (orders / orders_items)

| Pole w API | Opis | Mapowanie na nexo PRO |
|------------|------|----------------------|
| `orders_id` | ID zamówienia | `DokumentHandlowy.Id` |
| `orders_code_customers_id` | Klient | `DokumentHandlowy.Kontrahent` |
| `orders_date` | Data wystawienia | `DokumentHandlowy.DataWystawienia` |
| `orders_status` | Status (Nowe/Wysłane) | Status własny |
| `orders_notes` | Uwagi | `DokumentHandlowy.Uwagi` |
| `orders_items_code_products_id` | Produkt | `Pozycja.Towar` |
| `orders_items_quantity` | Ilość | `Pozycja.Ilosc` |
| `orders_items_quantity_extra` | Gratis | Atrybut własny |
| `orders_items_price_netto` | Cena netto | `Pozycja.CenaNetto` |
| `orders_items_discount` | Rabat | `Pozycja.Rabat` |
| `orders_items_desc` | Uwagi do pozycji | `Pozycja.Opis` |

#### 📋 OFERTA (offers / offers_items)

Struktura analogiczna do zamówienia, z dodatkowymi polami:
- `offers_valid_to` - Data ważności oferty
- `offers_email` - Email do wysyłki

#### 📂 SCHOWEK (clipboards / clipboards_items)

| Pole | Opis |
|------|------|
| `clipboards_id` | ID schowka |
| `clipboards_name` | Nazwa schowka |
| `clipboards_items_code_products_id` | Produkt |
| `clipboards_items_quantity` | Ilość |

---

## 2. 📋 SPECYFIKACJA FUNKCJONALNA (Gap Analysis)

### 2.1 Funkcje widoczne na ekranach

| # | Funkcja | Ekran | Niezbędna? | Priorytet |
|---|---------|-------|------------|-----------|
| **LOGOWANIE** |
| F01 | Logowanie login/hasło | Login | ✅ TAK | P0 |
| F02 | Zapamiętanie sesji | Login | ✅ TAK | P0 |
| **DASHBOARD** |
| F03 | Wyświetlanie nazwy handlowca | Dashboard | ✅ TAK | P0 |
| F04 | Nawigacja do modułów (6 kafelków) | Dashboard | ✅ TAK | P0 |
| F05 | Wyszukiwanie globalne (lupka) | Dashboard | ⚠️ NICE | P2 |
| F06 | Ręczna synchronizacja | Dashboard | ✅ TAK | P0 |
| **PRODUKTY** |
| F07 | Lista produktów z paginacją | Produkty | ✅ TAK | P0 |
| F08 | Wyświetlanie: kod, nazwa, cena, jednostka | Produkty | ✅ TAK | P0 |
| F09 | Zdjęcia produktów | Produkty | ⚠️ NICE | P2 |
| F10 | Wyszukiwanie po nazwie | Produkty | ✅ TAK | P0 |
| F11 | Skanowanie kodu kreskowego | Produkty | ⚠️ NICE | P2 |
| F12 | Wyszukiwanie głosowe | Produkty | ❌ NIE | P3 |
| F13 | Prezentacja (slideshow) | Produkty | ❌ NIE | P3 |
| F14 | Zaznaczanie wielu produktów | Produkty | ⚠️ NICE | P2 |
| **KLIENCI** |
| F15 | Lista klientów | Klienci | ✅ TAK | P0 |
| F16 | Dane: nazwa, adres, NIP, telefon | Klienci | ✅ TAK | P0 |
| F17 | "Pracuj z klientem" (wybór kontekstu) | Klienci | ✅ TAK | P0 |
| F18 | "Pracuj bez klienta" | Klienci | ✅ TAK | P1 |
| F19 | Szczegóły klienta | Klienci | ✅ TAK | P0 |
| F20 | Dane finansowe (rozliczenia) | Klienci | ⚠️ NICE | P2 |
| F21 | Dodawanie nowego klienta | Klienci | ⚠️ NICE | P2 |
| F22 | Edycja klienta | Klienci | ❌ NIE | P3 |
| F23 | Pobieranie danych z GUS (NIP) | Klienci | ❌ NIE | P3 |
| **KOSZYK** |
| F24 | Dodawanie produktu do koszyka | Koszyk | ✅ TAK | P0 |
| F25 | Edycja ilości | Koszyk | ✅ TAK | P0 |
| F26 | Usuwanie pozycji | Koszyk | ✅ TAK | P0 |
| F27 | Ilość dodatkowa (Gratis) | Koszyk | ⚠️ NICE | P2 |
| F28 | Zmiana ceny przez handlowca | Koszyk | ⚠️ NICE | P1 |
| F29 | Komentarz do pozycji | Koszyk | ⚠️ NICE | P2 |
| F30 | Podsumowanie Netto/Brutto/VAT | Koszyk | ✅ TAK | P0 |
| F31 | Czyszczenie koszyka | Koszyk | ✅ TAK | P1 |
| **ZAMÓWIENIA** |
| F32 | Tworzenie zamówienia z koszyka | Zamówienia | ✅ TAK | P0 |
| F33 | Historia zamówień | Zamówienia | ✅ TAK | P0 |
| F34 | Statusy: Nowe, Wysłane | Zamówienia | ✅ TAK | P0 |
| F35 | Szczegóły zamówienia (pozycje) | Zamówienia | ✅ TAK | P0 |
| F36 | Uwagi do zamówienia | Zamówienia | ⚠️ NICE | P1 |
| **OFERTY** |
| F37 | Tworzenie oferty z koszyka | Oferty | ⚠️ NICE | P1 |
| F38 | Historia ofert | Oferty | ⚠️ NICE | P1 |
| F39 | Wysyłka oferty mailem | Oferty | ❌ NIE | P3 |
| **SCHOWKI** |
| F40 | Zapisywanie koszyka do schowka | Schowki | ⚠️ NICE | P2 |
| F41 | Wczytywanie ze schowka | Schowki | ⚠️ NICE | P2 |
| F42 | Lista schowków | Schowki | ⚠️ NICE | P2 |
| **SYNCHRONIZACJA** |
| F43 | Automatyczna synchronizacja w tle | System | ✅ TAK | P0 |
| F44 | Praca offline | System | ✅ TAK | P0 |
| F45 | Konflikt danych (rozwiązywanie) | System | ⚠️ NICE | P2 |

### 2.2 Legenda priorytetów

| Priorytet | Opis | Termin |
|-----------|------|--------|
| **P0** | Krytyczne - MVP | Faza 1 |
| **P1** | Ważne - Beta | Faza 1 |
| **P2** | Nice-to-have | Faza 2 |
| **P3** | Opcjonalne | Przyszłość |

### 2.3 Funkcje zbędne dla procesu Zamówienie → nexo PRO

Na podstawie analizy, następujące funkcje z oryginalnej aplikacji **nie są wymagane** dla podstawowego procesu:

1. **Raporty/Ankiety (poll)** - Specyficzne dla poprzedniego wdrożenia
2. **GPS/Trasówka** - Niezwiązane z zamówieniami
3. **Tankowanie (fuel)** - Funkcja rozliczania floty
4. **Kontakty z kalendarzem** - CRM wykraczający poza zakres
5. **Wyszukiwanie głosowe** - Gadżet, nie core function
6. **Prezentacja slajdów** - Marketing, nie sprzedaż
7. **Pobieranie z GUS** - Można dodać później

---

## 3. 🔐 ARCHITEKTURA OBSŁUGI UŻYTKOWNIKÓW

### 3.1 Model autoryzacji (z analizy API)

```
┌────────────────────────────────────────────────────────────────────┐
│                      FLOW AUTORYZACJI                              │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  1. Handlowiec wprowadza: username + password                      │
│                                                                    │
│  2. API POST /api_android/login                                    │
│     Request: { username, password }                                │
│     Response: { token, user_id, client_id, config... }             │
│                                                                    │
│  3. Token zapisywany lokalnie (SharedPreferences)                  │
│                                                                    │
│  4. Każdy kolejny request zawiera: Authorization: Bearer <token>   │
│                                                                    │
│  5. Przy synchronizacji zamówień:                                  │
│     - user_id → identyfikuje handlowca                             │
│     - client_id → identyfikuje firmę/klienta API                   │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

### 3.2 Propozycja modelu dla 4 handlowców

#### Wariant A: Proste konta w Cloud API

```json
// Tabela: salesmen (handlowcy)
{
  "id": 1,
  "username": "jan.kowalski",
  "password_hash": "...",
  "full_name": "Jan Kowalski",
  "email": "jan@firma.pl",
  "nexo_operator_id": "JK",      // Mapowanie na operatora nexo
  "nexo_salesman_id": 123,       // ID opiekuna w nexo (jeśli używany)
  "active": true,
  "client_id": 1                 // FK do clients (firmy klienta)
}
```

#### Wariant B: Mapowanie na opiekuna w nexo PRO

W InsERT nexo PRO kontrahent może mieć przypisanego **Opiekuna**. Można to wykorzystać:

```
Zamówienie z aplikacji → Cloud API → Nexo Bridge → nexo PRO
                                         │
                                         ▼
                        Dokument.Operator = nexo_operator_id
                        Kontrahent.Opiekun = nexo_salesman_id
```

#### Rekomendacja

**Wariant A + B połączone:**
1. Cloud API przechowuje konta handlowców z mapowaniem na nexo
2. Przy tworzeniu dokumentu w nexo, ustawiany jest odpowiedni Operator
3. Raporty sprzedaży można generować per Operator/Opiekun

### 3.3 Skalowalność (dodawanie kolejnych handlowców)

```sql
-- Wystarczy INSERT do tabeli salesmen
INSERT INTO salesmen (username, password_hash, full_name, nexo_operator_id, client_id)
VALUES ('nowy.handlowiec', 'hash', 'Nowy Handlowiec', 'NH', 1);

-- Lub przez panel admina (do implementacji w przyszłości)
```

**Ważne:** Stare API nie miało panelu admina - konta były tworzone ręcznie w bazie. Nowy system powinien umożliwiać:
- Dodawanie handlowców przez administratora
- Dezaktywację kont (bez usuwania - historia zamówień)
- Reset hasła

---

## 4. 🧪 SCENARIUSZE TESTOWE (Test Plan)

### 4.1 Testy logowania i autoryzacji

| ID | Nazwa | Kroki | Oczekiwany rezultat |
|----|-------|-------|---------------------|
| TC01 | Logowanie poprawne | 1. Wprowadź poprawny login/hasło 2. Kliknij "Zaloguj" | Przekierowanie na Dashboard, nazwa handlowca widoczna |
| TC02 | Logowanie - złe hasło | 1. Wprowadź poprawny login, złe hasło 2. Kliknij "Zaloguj" | Komunikat błędu, pozostanie na ekranie logowania |
| TC03 | Logowanie - brak sieci | 1. Wyłącz WiFi/dane 2. Spróbuj zalogować | Komunikat "Brak połączenia" lub logowanie offline (jeśli był wcześniej zalogowany) |
| TC04 | Wylogowanie | 1. Z Dashboard wybierz "Wyloguj" 2. Potwierdź | Powrót do ekranu logowania, dane lokalne usunięte |
| TC05 | Sesja wygasła | 1. Zaloguj się 2. Poczekaj >24h bez synchronizacji | Komunikat o konieczności ponownego logowania |

### 4.2 Testy synchronizacji danych

| ID | Nazwa | Kroki | Oczekiwany rezultat |
|----|-------|-------|---------------------|
| TC10 | Sync produktów - pierwszy raz | 1. Zaloguj się 2. Wejdź w Produkty | Lista produktów załadowana z serwera |
| TC11 | Sync produktów - aktualizacja | 1. Zmień cenę produktu w nexo 2. Synchronizuj w aplikacji | Nowa cena widoczna na tablecie |
| TC12 | Sync klientów | 1. Dodaj klienta w nexo 2. Synchronizuj | Nowy klient widoczny na liście |
| TC13 | Sync offline | 1. Wyłącz sieć 2. Utwórz zamówienie 3. Włącz sieć 4. Synchronizuj | Zamówienie wysłane, status zmieniony na "Wysłane" |
| TC14 | Sync - konflikt | 1. Zmień dane klienta w nexo 2. Jednocześnie edytuj w aplikacji | Rozwiązanie konfliktu (server wins / timestamp) |

### 4.3 Testy procesu zamówienia

| ID | Nazwa | Kroki | Oczekiwany rezultat |
|----|-------|-------|---------------------|
| TC20 | Dodanie produktu do koszyka | 1. Wejdź w Produkty 2. Wybierz produkt 3. Wprowadź ilość 4. "Do koszyka" | Produkt w koszyku z poprawną ilością i ceną |
| TC21 | Edycja ilości w koszyku | 1. Wejdź w Koszyk 2. Kliknij pozycję 3. Zmień ilość | Wartość pozycji przeliczona |
| TC22 | Usunięcie pozycji | 1. W koszyku wybierz pozycję 2. "Usuń" | Pozycja usunięta, suma przeliczona |
| TC23 | Zamówienie bez klienta | 1. Dodaj produkty do koszyka 2. "Zamów" bez wybrania klienta | Komunikat "Wybierz klienta" lub zamówienie bez klienta |
| TC24 | Zamówienie z klientem | 1. Wybierz klienta 2. Dodaj produkty 3. "Zamów" 4. Wpisz uwagi 5. Potwierdź | Zamówienie utworzone, widoczne w historii jako "Nowe" |
| TC25 | Weryfikacja cen z nexo | 1. Sprawdź cenę produktu w nexo 2. Sprawdź tę samą cenę na tablecie | Ceny identyczne |
| TC26 | Rabat klienta | 1. Ustaw rabat 10% dla klienta w nexo 2. Synchronizuj 3. Dodaj produkt | Cena po rabacie poprawna |
| TC27 | Zamówienie → nexo PRO | 1. Utwórz zamówienie 2. Synchronizuj 3. Sprawdź w nexo | Dokument ZK widoczny w nexo z poprawnymi danymi |

### 4.4 Testy wydajności i edge cases

| ID | Nazwa | Kroki | Oczekiwany rezultat |
|----|-------|-------|---------------------|
| TC30 | Duża lista produktów | 1. Załaduj bazę >10000 produktów 2. Przewijaj listę | Płynne przewijanie, brak lagów |
| TC31 | Wyszukiwanie | 1. Wpisz fragment nazwy 2. Obserwuj wyniki | Wyniki <500ms, poprawne filtrowanie |
| TC32 | Brak miejsca na dysku | 1. Zapełnij pamięć tabletu 2. Spróbuj synchronizować | Komunikat o braku miejsca |
| TC33 | Przerwane połączenie | 1. Rozpocznij sync 2. W trakcie wyłącz WiFi | Retry lub komunikat, brak uszkodzonych danych |
| TC34 | Wielokrotne kliknięcie | 1. Kliknij "Zamów" szybko 5 razy | Tylko jedno zamówienie utworzone |

### 4.5 Testy UI/UX

| ID | Nazwa | Kroki | Oczekiwany rezultat |
|----|-------|-------|---------------------|
| TC40 | Orientacja landscape | 1. Obróć tablet do landscape | UI poprawnie skalowane |
| TC41 | Czytelność na słońcu | 1. Wyjdź na zewnątrz 2. Spróbuj używać aplikacji | Kontrast wystarczający |
| TC42 | Przyciski dla palców | 1. Używaj aplikacji palcami | Wszystkie elementy klikalne bez problemu (min 48dp) |

---

## 5. ⚠️ POTENCJALNE RYZYKA I PYTANIA DO KLIENTA

### 5.1 Pytania wymagające wyjaśnienia

#### Cenniki i rabaty

| # | Pytanie | Kontekst z API |
|---|---------|----------------|
| Q01 | **Czy używacie grupy cenowych w nexo?** | W API widzę `customers_wapro_groups_id` i `prices_groups` - sugeruje to grupy cenowe. |
| Q02 | **Czy używacie indywidualnych cen dla klientów?** | Tabela `prices_customers` sugeruje cenniki per klient. |
| Q03 | **Jak działa rabat discount1 vs discount2?** | Widzę dwa pola rabatowe - czy oba są używane? Jaki jest ich sens? |
| Q04 | **Czy promocje są wprowadzane w nexo czy w osobnym systemie?** | Pola `products_promo_*` sugerują osobny mechanizm promocji. |

#### Produkty

| # | Pytanie | Kontekst z API |
|---|---------|----------------|
| Q05 | **Czy pole "Gratis" (ilość dodatkowa) jest używane?** | `cart_quantity_extra` - czy klient daje gratisy do zamówień? |
| Q06 | **Skąd pochodzą zdjęcia produktów?** | `products_image_url` - osobny serwer plików? |
| Q07 | **Czy produkt może mieć wiele jednostek miary?** | W API widzę tylko `products_unit` |
| Q08 | **Czy wymagany jest kod kreskowy EAN?** | Obecny w API, ale czy używany w procesie? |

#### Klienci

| # | Pytanie | Kontekst z API |
|---|---------|----------------|
| Q09 | **Czy handlowiec może dodać nowego klienta w terenie?** | W starym API była taka opcja - czy potrzebna? |
| Q10 | **Czy klient ma przypisanego płatnika (payer_id)?** | `customers_wapro_payer_id` - np. centrala płaci za oddziały? |
| Q11 | **Czy handlowiec widzi należności klienta?** | W UI były "Rozliczenia klienta" i "Rozliczenia płatnika" |

#### Zamówienia

| # | Pytanie | Kontekst z API |
|---|---------|----------------|
| Q12 | **Jaki typ dokumentu tworzony w nexo?** | ZK (Zamówienie od Klienta)? FV? WZ? |
| Q13 | **Czy zamówienie może być edytowane po wysłaniu?** | W starym API był tylko status Nowe/Wysłane |
| Q14 | **Czy potrzebna jest funkcja Ofert (generowanie PDF)?** | Osobny moduł w starym API |

#### Integracja

| # | Pytanie | Kontekst z API |
|---|---------|----------------|
| Q15 | **Która wersja nexo PRO?** | Wpływa na dostępność API Sfera |
| Q16 | **Czy nexo jest na dedykowanym serwerze czy lokalnie?** | Wpływa na architekturę Bridge |
| Q17 | **Czy są inne integracje z nexo (np. WMS, e-commerce)?** | Możliwe konflikty |

### 5.2 Zidentyfikowane ryzyka techniczne

| # | Ryzyko | Prawdopodobieństwo | Wpływ | Mitygacja |
|---|--------|-------------------|-------|-----------|
| R01 | **Niezgodność wersji Sfera SDK** | Średnie | Wysoki | Weryfikacja wersji nexo przed wdrożeniem |
| R02 | **Duża baza produktów (>50k)** | Niskie | Średni | Paginacja, indeksy w SQLite |
| R03 | **Słabe WiFi w terenie** | Wysokie | Średni | Robust offline mode, retry logic |
| R04 | **Stare tablety (Android 7.0)** | Wysokie | Średni | Testowanie na starszych urządzeniach |
| R05 | **Zmiana struktury danych w nexo** | Niskie | Wysoki | Wersjonowanie API, monitoring |

### 5.3 Rekomendacje przed wdrożeniem

1. **Spotkanie kick-off z klientem** - wyjaśnienie wszystkich pytań (Q01-Q17)
2. **Dostęp do testowej bazy nexo** - środowisko developerskie
3. **Lista handlowców** - login, email, mapowanie na operatorów nexo
4. **Przykładowe zamówienie** - end-to-end test ścieżki
5. **Tablet testowy** - identyczny model jak produkcyjny

---

## 6. 📎 ZAŁĄCZNIKI

### 6.1 Endpointy API (z reverse engineering)

```
Base URL: https://api.posdi.com/

Autoryzacja:
  POST /api_android/login              - logowanie
  POST /api_android/logout             - wylogowanie

Synchronizacja:
  POST /api_android/batchsync          - synchronizacja danych (batch)
  GET  /api_files/sync                 - synchronizacja plików (zdjęcia)

Kontakty/CRM:
  GET  /api_android/contacts/get_list      - lista kontaktów
  GET  /api_android/contacts/get_statuses  - statusy kontaktów

System:
  GET  /api_android/update_app         - sprawdzenie aktualizacji
```

### 6.2 Tabele SQLite (lokalna baza)

```
theme               - motywy graficzne
products            - produkty
customers           - klienci
cart                - koszyk (bieżący)
orders              - zamówienia
orders_items        - pozycje zamówień
offers              - oferty
offers_items        - pozycje ofert
clipboards          - schowki
clipboards_items    - pozycje schowków
config_app          - konfiguracja aplikacji
work_time           - czas pracy
kilometers          - trasówki
prices_customers    - ceny indywidualne
prices_groups       - ceny grupowe
prices              - cenniki
payments            - płatności/należności
gps                 - pozycje GPS
poll                - ankiety (wypełnione)
poll_items          - odpowiedzi ankiet
poll_def            - definicje ankiet
poll_def_items      - pytania ankiet
fuel                - tankowania
cars                - samochody
```

### 6.3 Stałe konfiguracyjne (z kodu)

```java
MAX_DISCOUNT = 15.0;              // Maksymalny rabat ręczny
DATA_SYNC_INTERVAL = 15 min;      // Interwał auto-sync
CONTACTS_SYNC_INTERVAL = 15 min;  // Interwał sync kontaktów
FILES_SYNC_INTERVAL = 15 min;     // Interwał sync plików
MAX_NO_SYNC_TIME = 24h;           // Maksymalny czas bez sync
PAGE_LIMIT = 15;                  // Elementy na stronie
GPS_RUN_TIME_DIFF = 300s;         // Częstotliwość zapisu GPS
```

---

---

## 7. 🚀 STATUS REALIZACJI (Nowa aplikacja IKO)

Na podstawie powyższej analizy starej aplikacji POSDI **została zbudowana nowa aplikacja IKO Mobile**:

### 7.1 Co zostało zrealizowane

| Komponent | Technologia | Status |
|-----------|-------------|--------|
| **IKO Mobile App** | Flutter (Dart) | ✅ 95% gotowe |
| **IKO Cloud API** | NestJS + PostgreSQL | ✅ 100% gotowe |
| **IKO Nexo Bridge** | .NET 8.0 + Sfera SDK | ✅ Gotowe do wdrożenia |

### 7.2 Funkcje zrealizowane vs. wzorzec POSDI

| Funkcja z POSDI | Zrealizowane w IKO | Uwagi |
|-----------------|-------------------|-------|
| Dashboard 6 kafelków | ✅ | Identyczny układ |
| Logo IKO | ✅ | Nowe logo klienta |
| Lista produktów | ✅ | Z wyszukiwaniem |
| Lista klientów | ✅ | Z szczegółami |
| Koszyk | ✅ | Pełna funkcjonalność |
| Zamówienia | ✅ | Tworzenie + historia |
| Oferty | ✅ | Tworzenie + konwersja |
| Schowki | ✅ | Zapisywanie koszyków |
| Sync offline | ✅ | SQLite + batch sync |
| Skaner kodów | ⏳ | Do dodania w P2 |
| GPS/Trasówka | ❌ | Poza zakresem |
| Raporty/Ankiety | ❌ | Poza zakresem |

### 7.3 Różnice między POSDI a IKO

| Aspekt | Stara aplikacja POSDI | Nowa aplikacja IKO |
|--------|----------------------|-------------------|
| **Platforma** | Android Native (Java) | Flutter (cross-platform) |
| **Backend** | api.posdi.com (zewnętrzny) | Cloud API (własny, NestJS) |
| **ERP** | WAPRO (wg. pól `_wapro_`) | InsERT nexo PRO |
| **Integracja** | Nieznana | Nexo Bridge + Sfera SDK |
| **Branding** | "Powered by HIVEDI" | "Powered by PRODAUT" |
| **Offline** | SQLite | SQLite (zachowane) |

### 7.4 Repozytoria projektu

| Repozytorium | Opis |
|--------------|------|
| `mastermi-ai/iko-mobile-app` | Aplikacja Flutter |
| `mastermi-ai/iko-cloud-api` | Backend NestJS |
| `mastermi-ai/iko-nexo-bridge` | Most do nexo PRO |

---

**Autor raportu:** Analityk Systemowy / AI Assistant  
**Data:** Styczeń 2026  
**Status:** ✅ Analiza zakończona, implementacja zrealizowana

---

*Ten raport został wygenerowany na podstawie analizy reverse engineering **starej aplikacji POSDI.apk** (wzorca) oraz zrzutów ekranu z folderu `baza/`. Na tej podstawie została zbudowana nowa aplikacja **IKO Mobile** z integracją z InsERT nexo PRO.*
