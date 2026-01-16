# 🏢 IKO Mobile System - Wdrożenie On-Premise (wszystko u klienta)

## 📋 Scenariusz

Klient chce mieć **cały system** na swoich serwerach:
- ✅ Cloud API (zamiast naszego serwera)
- ✅ Baza PostgreSQL (dla API)
- ✅ Nexo Bridge
- ✅ InsERT nexo PRO (już ma)

---

## 🖥️ Wymagania sprzętowe

### Serwer dla Cloud API + Nexo Bridge

| Komponent | Minimum | Zalecane |
|-----------|---------|----------|
| **CPU** | 2 rdzenie | 4 rdzenie |
| **RAM** | 4 GB | 8 GB |
| **Dysk** | 50 GB SSD | 100 GB SSD |
| **System** | Windows Server 2019 | Windows Server 2022 |

**Alternatywnie:** Osobne serwery dla API (Linux) i Bridge (Windows)

### Wymagania sieciowe

```
┌─────────────────────────────────────────────────────────────────┐
│                    SIEĆ KLIENTA                                 │
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│  │ SQL Server  │    │ Cloud API   │    │ Nexo Bridge │        │
│  │ (nexo PRO)  │◀──▶│ + PostgreSQL│◀──▶│ (Windows)   │        │
│  │ Port: 1433  │    │ Port: 3000  │    │             │        │
│  └─────────────┘    └──────┬──────┘    └─────────────┘        │
│                            │                                   │
│                            │ Port: 443 (HTTPS)                 │
│                            ▼                                   │
│                    ┌───────────────┐                           │
│                    │   Firewall    │                           │
│                    │   / Router    │                           │
│                    └───────┬───────┘                           │
│                            │                                   │
└────────────────────────────┼───────────────────────────────────┘
                             │
                             ▼ INTERNET
                    ┌───────────────┐
                    │  📱 Tablety   │
                    │  handlowców   │
                    └───────────────┘
```

---

## 🚀 ETAP 1: Przygotowanie serwera (Windows Server)

### 1.1 Instalacja wymaganych komponentów

```powershell
# Jako Administrator

# 1. Zainstaluj .NET 8.0 Runtime
# Pobierz: https://dotnet.microsoft.com/download/dotnet/8.0
# Lub przez winget:
winget install Microsoft.DotNet.Runtime.8

# 2. Zainstaluj Node.js 20 LTS
winget install OpenJS.NodeJS.LTS

# 3. Zainstaluj PostgreSQL 15+
winget install PostgreSQL.PostgreSQL

# 4. Zainstaluj Git
winget install Git.Git

# Zrestartuj PowerShell po instalacji
```

### 1.2 Alternatywa: Docker (prostsze)

```powershell
# Zainstaluj Docker Desktop for Windows
winget install Docker.DockerDesktop

# Uruchom Docker Desktop i włącz WSL2 backend
```

---

## 🗄️ ETAP 2: Instalacja Cloud API

### OPCJA A: Z Docker (ZALECANA)

```powershell
# 1. Pobierz kod
cd C:\
git clone https://github.com/mastermi-ai/iko-cloud-api.git
cd iko-cloud-api

# 2. Utwórz plik .env
@"
DATABASE_URL=postgresql://iko_user:silne_haslo_123@postgres:5432/iko_db
JWT_SECRET=$(openssl rand -hex 32)
BRIDGE_API_KEY=$(openssl rand -hex 16)
NODE_ENV=production
PORT=3000
"@ | Out-File -Encoding utf8 .env

# 3. Uruchom z Docker
docker-compose up -d

# 4. Sprawdź status
docker-compose ps
docker-compose logs -f
```

**docker-compose.yml** (jeśli nie ma w repo):
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: iko_user
      POSTGRES_PASSWORD: silne_haslo_123
      POSTGRES_DB: iko_db
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: always

  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://iko_user:silne_haslo_123@postgres:5432/iko_db
      - JWT_SECRET=${JWT_SECRET}
      - BRIDGE_API_KEY=${BRIDGE_API_KEY}
    depends_on:
      - postgres
    restart: always

volumes:
  postgres_data:
```

### OPCJA B: Bez Docker (natywnie)

```powershell
# 1. Utwórz bazę PostgreSQL
psql -U postgres
CREATE DATABASE iko_db;
CREATE USER iko_user WITH PASSWORD 'silne_haslo_123';
GRANT ALL PRIVILEGES ON DATABASE iko_db TO iko_user;
\q

# 2. Pobierz kod
cd C:\
git clone https://github.com/mastermi-ai/iko-cloud-api.git
cd iko-cloud-api

# 3. Utwórz plik .env
@"
DATABASE_URL=postgresql://iko_user:silne_haslo_123@localhost:5432/iko_db
JWT_SECRET=wygeneruj_silny_klucz_jwt_min_32_znaki
BRIDGE_API_KEY=wygeneruj_klucz_dla_bridge_16_znakow
NODE_ENV=production
PORT=3000
"@ | Out-File -Encoding utf8 .env

# 4. Zainstaluj zależności
npm install

# 5. Uruchom migracje bazy
npx prisma migrate deploy

# 6. Uruchom seed (dane początkowe)
npx prisma db seed

# 7. Zbuduj aplikację
npm run build

# 8. Uruchom
npm run start:prod
```

### 2.3 Instalacja API jako Windows Service

```powershell
# Użyj NSSM (Non-Sucking Service Manager)
# Pobierz: https://nssm.cc/download

# Instalacja NSSM
Expand-Archive nssm-2.24.zip -DestinationPath C:\nssm
$env:Path += ";C:\nssm\nssm-2.24\win64"

# Utwórz serwis
nssm install IkoCloudApi "C:\Program Files\nodejs\node.exe"
nssm set IkoCloudApi AppDirectory "C:\iko-cloud-api"
nssm set IkoCloudApi AppParameters "dist\main.js"
nssm set IkoCloudApi DisplayName "IKO Cloud API"
nssm set IkoCloudApi Description "API dla systemu IKO Mobile"
nssm set IkoCloudApi Start SERVICE_AUTO_START

# Uruchom serwis
nssm start IkoCloudApi
```

---

## 🔗 ETAP 3: Instalacja Nexo Bridge

```powershell
# 1. Pobierz kod
cd C:\
git clone https://github.com/mastermi-ai/iko-nexo-bridge.git
cd iko-nexo-bridge

# 2. Zbuduj
dotnet publish -c Release -o C:\IkoNexoBridge

# 3. Skonfiguruj appsettings.json
```

Edytuj `C:\IkoNexoBridge\appsettings.json`:

```json
{
  "CloudApi": {
    "BaseUrl": "http://localhost:3000",
    "ApiKey": "TEN_SAM_KLUCZ_CO_W_ENV_BRIDGE_API_KEY",
    "ClientId": 1,
    "PollingIntervalSeconds": 30
  },
  "NexoPro": {
    "ServerName": "localhost\\NEXO",
    "DatabaseName": "NexoPRO",
    "Username": "",
    "Password": ""
  },
  "Sync": {
    "SyncOrdersEnabled": true,
    "SyncProductsEnabled": true,
    "SyncCustomersEnabled": true,
    "ProductsSyncIntervalMinutes": 60,
    "CustomersSyncIntervalMinutes": 60
  }
}
```

```powershell
# 4. Zainstaluj jako serwis
sc.exe create "IkoNexoBridge" binPath="C:\IkoNexoBridge\IkoNexoBridge.exe" start=auto
sc.exe start IkoNexoBridge
```

---

## 🌐 ETAP 4: Konfiguracja dostępu z internetu

### OPCJA A: Reverse Proxy z IIS

```powershell
# 1. Zainstaluj IIS z URL Rewrite i ARR
Install-WindowsFeature Web-Server -IncludeManagementTools
# Pobierz i zainstaluj:
# - URL Rewrite: https://www.iis.net/downloads/microsoft/url-rewrite
# - ARR: https://www.iis.net/downloads/microsoft/application-request-routing

# 2. Utwórz nową stronę w IIS
# - Nazwa: IKO-API
# - Port: 443 (HTTPS)
# - Binding: iko-api.firma-klienta.pl (domena klienta)
# - Certyfikat SSL: od Let's Encrypt lub kupiony

# 3. Skonfiguruj Reverse Proxy do localhost:3000
```

**web.config** dla IIS:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        <rewrite>
            <rules>
                <rule name="ReverseProxyToAPI" stopProcessing="true">
                    <match url="(.*)" />
                    <action type="Rewrite" url="http://localhost:3000/{R:1}" />
                </rule>
            </rules>
        </rewrite>
    </system.webServer>
</configuration>
```

### OPCJA B: nginx na Windows

```powershell
# 1. Pobierz nginx
Invoke-WebRequest -Uri "https://nginx.org/download/nginx-1.24.0.zip" -OutFile nginx.zip
Expand-Archive nginx.zip -DestinationPath C:\nginx

# 2. Skonfiguruj nginx.conf
```

**C:\nginx\conf\nginx.conf**:
```nginx
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    upstream api_backend {
        server 127.0.0.1:3000;
    }

    server {
        listen 80;
        server_name iko-api.firma-klienta.pl;
        
        # Redirect to HTTPS
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl;
        server_name iko-api.firma-klienta.pl;

        ssl_certificate     C:/nginx/ssl/cert.pem;
        ssl_certificate_key C:/nginx/ssl/key.pem;

        location / {
            proxy_pass http://api_backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_cache_bypass $http_upgrade;
        }
    }
}
```

```powershell
# 3. Uruchom nginx
cd C:\nginx
start nginx

# 4. Zainstaluj jako serwis (opcjonalnie)
# Użyj NSSM jak dla Node.js
```

### OPCJA C: Cloudflare Tunnel (najprostsza)

```powershell
# 1. Zainstaluj cloudflared
winget install Cloudflare.cloudflared

# 2. Zaloguj się do Cloudflare
cloudflared tunnel login

# 3. Utwórz tunel
cloudflared tunnel create iko-api

# 4. Skonfiguruj tunel
@"
tunnel: ID_TUNELU
credentials-file: C:\Users\Administrator\.cloudflared\ID_TUNELU.json

ingress:
  - hostname: iko-api.firma-klienta.pl
    service: http://localhost:3000
  - service: http_status:404
"@ | Out-File -Encoding utf8 C:\Users\Administrator\.cloudflared\config.yml

# 5. Uruchom jako serwis
cloudflared service install
```

---

## 🔒 ETAP 5: Konfiguracja Firewall

```powershell
# Otwórz port 443 dla HTTPS (dostęp z internetu)
New-NetFirewallRule -DisplayName "IKO API HTTPS" -Direction Inbound -Port 443 -Protocol TCP -Action Allow

# Blokuj bezpośredni dostęp do portów wewnętrznych z zewnątrz
# Port 3000 (API) - tylko lokalnie
# Port 5432 (PostgreSQL) - tylko lokalnie
# Port 1433 (SQL Server) - tylko lokalnie
```

---

## 📱 ETAP 6: Konfiguracja aplikacji mobilnej

### 6.1 Zmień URL API w kodzie aplikacji

Przed budowaniem APK, edytuj:

**`lib/services/api_service.dart`:**
```dart
class ApiService {
  // URL API klienta
  static const String baseUrl = 'https://iko-api.firma-klienta.pl';
  // ...
}
```

### 6.2 Zbuduj APK dla klienta

```bash
cd iko-mobile-app
flutter build apk --release
```

### 6.3 Podpisz APK (opcjonalnie)

```bash
# Utwórz keystore (raz)
keytool -genkey -v -keystore iko-release.keystore -alias iko -keyalg RSA -keysize 2048 -validity 10000

# Skonfiguruj android/key.properties
# Zbuduj z podpisem
flutter build apk --release
```

---

## 🧪 ETAP 7: Testowanie całego systemu

### 7.1 Test Cloud API

```powershell
# Z serwera
curl http://localhost:3000/bridge/health
# Powinno zwrócić: {"status":"ok"...}

# Z zewnątrz (przez domenę)
curl https://iko-api.firma-klienta.pl/bridge/health
```

### 7.2 Test Nexo Bridge

```powershell
# Sprawdź logi
Get-Content C:\IkoNexoBridge\logs\*.log -Tail 20

# Powinno pokazać:
# Successfully connected to nexo PRO
# Processing X pending orders
```

### 7.3 Test aplikacji mobilnej

1. Zainstaluj APK na tablecie
2. Połącz tablet z internetem (WiFi lub dane mobilne)
3. Zaloguj się kontem handlowca
4. Sprawdź czy produkty się ładują
5. Złóż testowe zamówienie
6. Sprawdź w nexo PRO czy zamówienie się pojawiło

---

## 📊 Architektura On-Premise

```
┌──────────────────────────────────────────────────────────────────────┐
│                        SERWER KLIENTA                                │
│                                                                      │
│   ┌────────────────────────────────────────────────────────────┐    │
│   │                     Windows Server                          │    │
│   │                                                             │    │
│   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │    │
│   │  │ PostgreSQL  │  │ Cloud API   │  │    Nexo Bridge      │ │    │
│   │  │ (baza IKO)  │  │ (Node.js)   │  │    (.NET 8.0)       │ │    │
│   │  │ Port: 5432  │  │ Port: 3000  │  │                     │ │    │
│   │  └─────────────┘  └──────┬──────┘  └──────────┬──────────┘ │    │
│   │                          │                     │            │    │
│   │                          └─────────────────────┘            │    │
│   │                                   │                         │    │
│   └───────────────────────────────────┼─────────────────────────┘    │
│                                       │                              │
│   ┌───────────────────────────────────┼─────────────────────────┐    │
│   │              IIS / nginx (Reverse Proxy)                    │    │
│   │                     Port: 443 (HTTPS)                       │    │
│   └───────────────────────────────────┬─────────────────────────┘    │
│                                       │                              │
│   ┌───────────────────────────────────┼─────────────────────────┐    │
│   │                SQL Server (nexo PRO)                        │    │
│   │                     Port: 1433                              │    │
│   └─────────────────────────────────────────────────────────────┘    │
│                                       │                              │
└───────────────────────────────────────┼──────────────────────────────┘
                                        │
                          FIREWALL (port 443)
                                        │
                                        ▼
                              ┌─────────────────┐
                              │    INTERNET     │
                              │                 │
                              │  📱 Tablety     │
                              │  handlowców     │
                              └─────────────────┘
```

---

## 🔄 Backup i odtwarzanie

### Backup bazy PostgreSQL (Cloud API)

```powershell
# Codzienne o 2:00 w nocy
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
pg_dump -U iko_user -h localhost iko_db > "C:\Backups\iko_db_$timestamp.sql"

# Skonfiguruj w Task Scheduler
```

### Backup konfiguracji

```powershell
# Backup plików konfiguracyjnych
Copy-Item C:\iko-cloud-api\.env C:\Backups\env_backup.txt
Copy-Item C:\IkoNexoBridge\appsettings.json C:\Backups\appsettings_backup.json
```

### Odtwarzanie po awarii

```powershell
# 1. Odtwórz bazę PostgreSQL
psql -U iko_user -d iko_db < C:\Backups\iko_db_YYYYMMDD.sql

# 2. Uruchom serwisy
sc.exe start IkoCloudApi
sc.exe start IkoNexoBridge
```

---

## 📞 Wsparcie

### Logi do analizy problemów:

| Komponent | Lokalizacja logów |
|-----------|-------------------|
| Cloud API | `C:\iko-cloud-api\logs\` lub `docker logs iko-api` |
| Nexo Bridge | `C:\IkoNexoBridge\logs\` |
| PostgreSQL | Event Viewer → Applications |
| IIS | `C:\inetpub\logs\LogFiles\` |
| nginx | `C:\nginx\logs\` |

### Kontakt:

**Email:** support@prodaut.pl
**Telefon:** +48 XXX XXX XXX

---

## ✅ Checklist wdrożenia On-Premise

- [ ] Serwer spełnia wymagania sprzętowe
- [ ] Zainstalowano .NET 8.0 Runtime
- [ ] Zainstalowano Node.js 20 LTS
- [ ] Zainstalowano PostgreSQL 15+
- [ ] Utworzono bazę danych iko_db
- [ ] Sklonowano i zbudowano Cloud API
- [ ] Skonfigurowano .env dla Cloud API
- [ ] Uruchomiono migracje Prisma
- [ ] Cloud API działa na porcie 3000
- [ ] Zainstalowano Cloud API jako serwis
- [ ] Sklonowano i zbudowano Nexo Bridge
- [ ] Skonfigurowano appsettings.json
- [ ] Nexo Bridge łączy się z nexo PRO
- [ ] Zainstalowano Nexo Bridge jako serwis
- [ ] Skonfigurowano reverse proxy (IIS/nginx)
- [ ] Skonfigurowano certyfikat SSL
- [ ] Otwarto port 443 w firewall
- [ ] API dostępne z internetu przez HTTPS
- [ ] Zbudowano APK z URL klienta
- [ ] Przetestowano logowanie z tabletu
- [ ] Przetestowano synchronizację produktów
- [ ] Przetestowano składanie zamówień
- [ ] Skonfigurowano backup bazy danych

---

*Wersja dokumentu: 1.0*
*Data: Styczeń 2026*
*© PRODAUT*
