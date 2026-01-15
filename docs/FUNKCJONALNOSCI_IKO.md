# 📱 IKO Mobile System - Spis Funkcjonalności

## 🎯 Przeznaczenie Systemu
**IKO Mobile System** to nowoczesna aplikacja mobilna dla handlowców, działająca na tabletach (Android/iOS) oraz w przeglądarce. System integruje się z **InsERT nexo PRO** poprzez Cloud API, umożliwiając pracę offline z automatyczną synchronizacją danych.

---

## 📲 APLIKACJA MOBILNA (Flutter)

### 🔐 1. LOGOWANIE I AUTORYZACJA
- Bezpieczne logowanie za pomocą nazwy użytkownika i hasła
- Autoryzacja JWT (token bezpieczeństwa)
- Automatyczne zapamiętywanie sesji
- Wylogowanie z poziomu ustawień

### 🏠 2. DASHBOARD (Panel Główny)
- Logo firmowe IKO
- Informacja o zalogowanym użytkowniku (firma)
- Szybki dostęp do wszystkich modułów:
  - 📦 Produkty
  - 👥 Klienci
  - 📋 Zamówienia
  - 🏷️ Oferty
  - 🛒 Koszyk
  - 📁 Schowki
- Przycisk synchronizacji danych (🔄)
- Globalne wyszukiwanie produktów (🔍)
- Stopka "Powered by PRODAUT"

### 📦 3. MODUŁ PRODUKTÓW
- **Lista produktów** z pełnym katalogiem towarów
- **Wyszukiwarka** - szybkie filtrowanie po nazwie lub kodzie
- **Szczegóły produktu:**
  - Nazwa i kod produktu
  - Cena netto / brutto
  - Stawka VAT
  - Jednostka miary (szt., kg, m, itp.)
  - Stan magazynowy
  - Opis produktu
- **Dodawanie do koszyka** bezpośrednio z karty produktu
- Praca offline - produkty zapisane lokalnie na urządzeniu

### 👥 4. MODUŁ KLIENTÓW (KONTRAHENCI)
- **Lista klientów** z pełną bazą kontrahentów z nexo PRO
- **Wyszukiwarka** klientów po nazwie, NIP lub kodzie
- **Szczegóły klienta:**
  - Nazwa firmy / Imię i Nazwisko
  - NIP
  - Adres (ulica, miasto, kod pocztowy)
  - Dane kontaktowe (telefon, email)
  - Limit kredytowy
  - Warunki płatności
- **Wybór klienta** do zamówienia/oferty
- Praca offline - klienci zapisani lokalnie

### 🛒 5. KOSZYK
- **Dodawanie produktów** z możliwością określenia ilości
- **Edycja ilości** produktów w koszyku
- **Usuwanie pozycji** z koszyka
- **Podsumowanie wartości:**
  - Suma Netto
  - Suma VAT
  - Suma Brutto
- **Wybór kontrahenta** dla zamówienia
- **Dwie opcje finalizacji:**
  - 📋 Złóż zamówienie
  - 🏷️ Utwórz ofertę
- **Możliwość zapisania** koszyka do schowka

### 📋 6. MODUŁ ZAMÓWIEŃ
- **Lista zamówień** z podziałem na zakładki:
  - ⏳ **Oczekujące** - zamówienia do wysłania
  - ✅ **Zsynchronizowane** - zamówienia wysłane do nexo PRO
- **Szczegóły zamówienia:**
  - Numer zamówienia
  - Data utworzenia
  - Kontrahent
  - Lista pozycji (produkty, ilości, ceny)
  - Wartość netto/brutto
  - Status zamówienia
  - Notatki
- **Statusy zamówień:**
  - `pending` - oczekujące na synchronizację
  - `synced` - wysłane do Cloud API
  - `processing` - przetwarzane przez Nexo Bridge
  - `completed` - zrealizowane w nexo PRO
  - `error` - błąd przetwarzania
- **Odświeżanie** listy (pull-to-refresh)

### 🏷️ 7. MODUŁ OFERT
- **Tworzenie ofert** dla klientów (alternatywa dla zamówienia)
- **Lista ofert** z podziałem na statusy:
  - 📝 Szkic (draft)
  - 📤 Wysłana
  - ✅ Zaakceptowana
  - ❌ Odrzucona
- **Szczegóły oferty:**
  - Numer oferty
  - Data ważności
  - Kontrahent
  - Lista pozycji
  - Wartość całkowita
- **Konwersja oferty na zamówienie** jednym kliknięciem
- Pełna historia ofert

### 📁 8. SCHOWKI (Zapisane Koszyki)
- **Zapisywanie** aktualnego stanu koszyka pod nazwą
- **Lista schowków** z datą utworzenia
- **Wczytywanie** schowka do koszyka
- **Zmiana nazwy** schowka
- **Usuwanie** niepotrzebnych schowków
- Idealne do przygotowywania powtarzalnych zamówień

### 🔄 9. SYNCHRONIZACJA DANYCH
- **Automatyczna synchronizacja** w tle (co 15 minut)
- **Ręczna synchronizacja** przyciskiem 🔄
- **Synchronizowane dane:**
  - ⬇️ Produkty (z nexo PRO → aplikacja)
  - ⬇️ Klienci (z nexo PRO → aplikacja)
  - ⬆️ Zamówienia (z aplikacji → Cloud API → nexo PRO)
  - ⬆️ Oferty (z aplikacji → Cloud API)
- **Wskaźnik postępu** synchronizacji
- **Powiadomienia** o wyniku synchronizacji

### 📴 10. PRACA OFFLINE
- Pełny dostęp do katalogu produktów bez internetu
- Pełny dostęp do listy klientów bez internetu
- Możliwość składania zamówień offline
- Możliwość tworzenia ofert offline
- Automatyczna synchronizacja po przywróceniu połączenia
- Lokalna baza danych SQLite na urządzeniu

---

## ☁️ CLOUD API (Serwer)

### 🔒 Autoryzacja
- JWT (JSON Web Tokens) dla bezpieczeństwa
- Osobne tokeny dla aplikacji mobilnej i Nexo Bridge
- Automatyczne odświeżanie sesji

### 📡 Endpointy API
| Endpoint | Opis |
|----------|------|
| `POST /auth/login` | Logowanie użytkownika |
| `GET /sync/products` | Pobieranie produktów |
| `GET /sync/customers` | Pobieranie klientów |
| `POST /orders` | Tworzenie zamówienia |
| `GET /orders` | Lista zamówień |
| `POST /quotes` | Tworzenie oferty |
| `GET /quotes` | Lista ofert |
| `PUT /quotes/:id/convert` | Konwersja oferty → zamówienie |

### 🗄️ Baza Danych
- PostgreSQL z Prisma ORM
- Pełna historia zamówień i ofert
- Relacje: Klienci → Zamówienia → Pozycje → Produkty

---

## 🔗 NEXO BRIDGE (Integracja z InsERT nexo PRO)

### ⚙️ Funkcje
- **Serwis Windows** działający 24/7
- Połączenie z InsERT nexo PRO przez **Sfera SDK**
- Automatyczne pobieranie zamówień z Cloud API
- Tworzenie dokumentów w nexo PRO (Zamówienia Od Odbiorców - ZO)
- Raportowanie statusu do Cloud API
- Obsługa błędów z logowaniem

### 🔄 Przepływ Danych
```
Tablet → Cloud API → Nexo Bridge → InsERT nexo PRO
                  ↓
         Status: completed/error
```

---

## 🎨 INTERFEJS UŻYTKOWNIKA

### Optymalizacja pod Tablet
- Duże, czytelne przyciski
- Orientacja pozioma (landscape)
- Siatka modułów 3x2
- Responsywne logo
- Czytelne fonty

### Kolorystyka
- Szara paleta kolorów (profesjonalna)
- Niebieski akcent na przyciskach modułów
- Zielone powiadomienia sukcesu
- Czerwone komunikaty błędów

---

## 📊 PODSUMOWANIE FUNKCJI

| Moduł | Funkcje |
|-------|---------|
| **Logowanie** | JWT, zapamiętywanie sesji |
| **Dashboard** | 6 modułów, sync, wyszukiwanie |
| **Produkty** | Lista, wyszukiwanie, szczegóły, dodaj do koszyka |
| **Klienci** | Lista, wyszukiwanie, szczegóły, wybór do zamówienia |
| **Koszyk** | Dodawanie, edycja, usuwanie, podsumowanie |
| **Zamówienia** | Tworzenie, lista, szczegóły, statusy |
| **Oferty** | Tworzenie, lista, konwersja na zamówienie |
| **Schowki** | Zapisywanie, wczytywanie, zarządzanie |
| **Synchronizacja** | Automatyczna + ręczna, offline-first |
| **Nexo Bridge** | Integracja z InsERT nexo PRO |

---

## 🚀 KORZYŚCI DLA UŻYTKOWNIKA

1. ✅ **Praca w terenie** - bez potrzeby dostępu do komputera
2. ✅ **Offline** - pełna funkcjonalność bez internetu
3. ✅ **Szybkość** - natychmiastowy dostęp do produktów i klientów
4. ✅ **Integracja** - automatyczne przesyłanie do nexo PRO
5. ✅ **Mobilność** - tablet zamiast laptopa
6. ✅ **Profesjonalizm** - oferty na miejscu u klienta

---

*Wersja: 1.0.0*
*Data: Styczeń 2026*
*Powered by PRODAUT*
