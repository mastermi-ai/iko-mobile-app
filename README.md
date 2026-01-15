# IKO Mobile Sales - Flutter App

Mobile application for salesman to manage orders, products, and customers with offline-first architecture.

## Features

✅ **Implemented:**
- Login screen with JWT authentication
- Dashboard with 6 modules
- Offline SQLite database
- Cloud API integration
- Data models (User, Product, Customer, Order)

🔄 **In Progress:**
- Product catalog
- Customer list
- Shopping cart
- Background sync

## Tech Stack

- **Flutter 3.38.7**
- **State Management**: flutter_bloc
- **Local Database**: sqflite  
- **HTTP Client**: dio
- **Storage**: shared_preferences

## Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Cloud API running on `http://localhost:3000`

### Installation

```bash
# Install dependencies
flutter pub get

# Run on iOS Simulator
flutter run -d "iPhone 15 Pro"

# Run on Android Emulator
flutter run -d emulator-5554
```

### Test Credentials

- Username: `demo_handlowiec`
- Password: `Test123!`

## Project Structure

```
lib/
├── main.dart              # App entry point
├── models/                # Data models
│   ├── user.dart
│   ├── product.dart
│   ├── customer.dart
│   └── order.dart
├── database/              # SQLite database
│   └── database_helper.dart
├── services/              # API services
│   └── api_service.dart
├── screens/               # UI screens
│   ├── login_screen.dart
│   └── dashboard_screen.dart
├── widgets/               # Reusable widgets
└── bloc/                  # State management
```

## Cloud API Configuration

Update `lib/services/api_service.dart` to point to your Cloud API:

```dart
static const String baseUrl = 'http://YOUR_API_URL:3000';
```

For iOS Simulator use: `http://localhost:3000`  
For Android Emulator use: `http://10.0.2.2:3000`

## Database Schema

### Products Table
- id, client_id, nexo_id, code, name, description
- image_url, price_netto, price_brutto, vat_rate
- unit, ean, active, synced_at

### Customers Table
- id, client_id, nexo_id, name, short_name
- address, postal_code, city, phone1, phone2
- email, nip, regon, voivodeship, synced_at

### Pending Orders Table
- local_id, customer_id, order_date, notes
- total_netto, total_brutto, items_json
- created_at, synced

## Next Steps

1. Product catalog screen with search
2. Customer list with filters
3. Shopping cart functionality
4. Order creation offline/online
5. Background sync service
6. Polish UI to match original app

## License

Proprietary - IKO System
