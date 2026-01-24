/// Kontrahent (Klient) z nexo PRO
///
/// ROZRACHUNKI (wymaganie klienta):
/// - Pole `balance` zawiera saldo należności klienta
/// - Wartość dodatnia = klient jest winien firmie
/// - Wartość ujemna = nadpłata klienta
/// - Pobierane z nexo przez Bridge
class Customer {
  final int id;
  final int clientId;
  final String? nexoId;
  final String name;
  final String? shortName;
  final String? address;
  final String? postalCode;
  final String? city;
  final String? phone1;
  final String? phone2;
  final String? email;
  final String? nip;
  final String? regon;
  final String? voivodeship;
  final DateTime? syncedAt;

  // ROZRACHUNKI - wymaganie klienta
  /// Saldo należności klienta (ile jest winien firmie)
  /// Wartość dodatnia = dług, ujemna = nadpłata
  final double? balance;
  /// Data ostatniej aktualizacji salda
  final DateTime? balanceUpdatedAt;
  /// Limit kredytowy klienta (opcjonalnie)
  final double? creditLimit;

  Customer({
    required this.id,
    required this.clientId,
    this.nexoId,
    required this.name,
    this.shortName,
    this.address,
    this.postalCode,
    this.city,
    this.phone1,
    this.phone2,
    this.email,
    this.nip,
    this.regon,
    this.voivodeship,
    this.syncedAt,
    this.balance,
    this.balanceUpdatedAt,
    this.creditLimit,
  });

  /// Czy klient ma zaległości
  bool get hasDebt => (balance ?? 0) > 0;

  /// Czy klient przekroczył limit kredytowy
  bool get isOverCreditLimit =>
      creditLimit != null && (balance ?? 0) > creditLimit!;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      clientId: json['clientId'] as int,
      nexoId: json['nexoId'] as String?,
      name: json['name'] as String,
      shortName: json['shortName'] as String?,
      address: json['address'] as String?,
      postalCode: json['postalCode'] as String?,
      city: json['city'] as String?,
      phone1: json['phone1'] as String?,
      phone2: json['phone2'] as String?,
      email: json['email'] as String?,
      nip: json['nip'] as String?,
      regon: json['regon'] as String?,
      voivodeship: json['voivodeship'] as String?,
      syncedAt: json['syncedAt'] != null
          ? DateTime.parse(json['syncedAt'] as String)
          : null,
      // Rozrachunki
      balance: json['balance'] != null
          ? (json['balance'] as num).toDouble()
          : null,
      balanceUpdatedAt: json['balanceUpdatedAt'] != null
          ? DateTime.parse(json['balanceUpdatedAt'] as String)
          : null,
      creditLimit: json['creditLimit'] != null
          ? (json['creditLimit'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'client_id': clientId,
      'nexo_id': nexoId,
      'name': name,
      'short_name': shortName,
      'address': address,
      'postal_code': postalCode,
      'city': city,
      'phone1': phone1,
      'phone2': phone2,
      'email': email,
      'nip': nip,
      'regon': regon,
      'voivodeship': voivodeship,
      'synced_at': syncedAt?.toIso8601String(),
      // Uwaga: balance, balance_updated_at, credit_limit nie są zapisywane
      // do lokalnej bazy - tabela SQLite ich nie ma. Dostępne tylko z API.
    };
  }

  factory Customer.fromDatabase(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int,
      clientId: map['client_id'] as int,
      nexoId: map['nexo_id'] as String?,
      name: map['name'] as String,
      shortName: map['short_name'] as String?,
      address: map['address'] as String?,
      postalCode: map['postal_code'] as String?,
      city: map['city'] as String?,
      phone1: map['phone1'] as String?,
      phone2: map['phone2'] as String?,
      email: map['email'] as String?,
      nip: map['nip'] as String?,
      regon: map['regon'] as String?,
      voivodeship: map['voivodeship'] as String?,
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'] as String)
          : null,
      // Rozrachunki
      balance: map['balance'] != null
          ? (map['balance'] as num).toDouble()
          : null,
      balanceUpdatedAt: map['balance_updated_at'] != null
          ? DateTime.parse(map['balance_updated_at'] as String)
          : null,
      creditLimit: map['credit_limit'] != null
          ? (map['credit_limit'] as num).toDouble()
          : null,
    );
  }

  /// Formatowane saldo do wyświetlenia
  String get formattedBalance {
    if (balance == null) return 'Brak danych';
    if (balance! > 0) return '+${balance!.toStringAsFixed(2)} zł (należność)';
    if (balance! < 0) return '${balance!.toStringAsFixed(2)} zł (nadpłata)';
    return '0.00 zł (rozliczone)';
  }
}
