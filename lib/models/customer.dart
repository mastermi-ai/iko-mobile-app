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
  });

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
    );
  }
}
