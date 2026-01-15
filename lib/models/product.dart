class Product {
  final int id;
  final int clientId;
  final String? nexoId;
  final String code;
  final String name;
  final String? description;
  final String? imageUrl;
  final double priceNetto;
  final double? priceBrutto;
  final double? vatRate;
  final String unit;
  final String? ean;
  final bool active;
  final DateTime? syncedAt;

  Product({
    required this.id,
    required this.clientId,
    this.nexoId,
    required this.code,
    required this.name,
    this.description,
    this.imageUrl,
    required this.priceNetto,
    this.priceBrutto,
    this.vatRate,
    required this.unit,
    this.ean,
    this.active = true,
    this.syncedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      clientId: json['clientId'] as int,
      nexoId: json['nexoId'] as String?,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      priceNetto: (json['priceNetto'] as num).toDouble(),
      priceBrutto: json['priceBrutto'] != null 
          ? (json['priceBrutto'] as num).toDouble() 
          : null,
      vatRate: json['vatRate'] != null 
          ? (json['vatRate'] as num).toDouble() 
          : null,
      unit: json['unit'] as String? ?? 'szt',
      ean: json['ean'] as String?,
      active: json['active'] as bool? ?? true,
      syncedAt: json['syncedAt'] != null 
          ? DateTime.parse(json['syncedAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'nexoId': nexoId,
      'code': code,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'priceNetto': priceNetto,
      'priceBrutto': priceBrutto,
      'vatRate': vatRate,
      'unit': unit,
      'ean': ean,
      'active': active,
      'syncedAt': syncedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'client_id': clientId,
      'nexo_id': nexoId,
      'code': code,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'price_netto': priceNetto,
      'price_brutto': priceBrutto,
      'vat_rate': vatRate,
      'unit': unit,
      'ean': ean,
      'active': active ? 1 : 0,
      'synced_at': syncedAt?.toIso8601String(),
    };
  }

  factory Product.fromDatabase(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      clientId: map['client_id'] as int,
      nexoId: map['nexo_id'] as String?,
      code: map['code'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      priceNetto: map['price_netto'] as double,
      priceBrutto: map['price_brutto'] as double?,
      vatRate: map['vat_rate'] as double?,
      unit: map['unit'] as String,
      ean: map['ean'] as String?,
      active: map['active'] == 1,
      syncedAt: map['synced_at'] != null 
          ? DateTime.parse(map['synced_at'] as String) 
          : null,
    );
  }
}
