/// Produkt (Towar) z nexo PRO
///
/// LOGIKA CEN (wymaganie klienta):
/// - `priceNetto` = CENA PÓŁKOWA (bazowa) wyświetlana handlowcowi
/// - Finalna kalkulacja rabatów następuje W NEXO po synchronizacji zamówienia
/// - Aplikacja NIE oblicza cen końcowych - tylko pokazuje cennik bazowy
///
/// ZDJĘCIA (wymaganie klienta - wydajność!):
/// - `thumbnailBase64` = cache zdjęcia jako Base64 (max 200x200px)
/// - Zdjęcia pobierane z nexo i cache'owane w Cloud API
///
/// SKANER EAN (wymaganie klienta):
/// - `ean` = kod kreskowy do skanowania kamerą/skanerem tabletu
class Product {
  final int id;
  final int clientId;
  final String? nexoId;
  final String code;
  final String name;
  final String? description;
  final String? imageUrl;
  /// Cena półkowa (bazowa) - rabaty obliczane w nexo!
  final double priceNetto;
  final double? priceBrutto;
  final double? vatRate;
  final String unit;
  /// Kod kreskowy EAN do skanowania
  final String? ean;
  final bool active;
  final DateTime? syncedAt;

  // ZDJĘCIA - cache z nexo (wymaganie klienta: wydajność!)
  /// Zdjęcie jako Base64 thumbnail (max 200x200px)
  final String? thumbnailBase64;
  /// Data pobrania zdjęcia z nexo
  final DateTime? thumbnailSyncedAt;

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
    this.thumbnailBase64,
    this.thumbnailSyncedAt,
  });

  /// Czy produkt ma zdjęcie (URL lub Base64)
  bool get hasImage =>
      (imageUrl != null && imageUrl!.isNotEmpty) ||
      (thumbnailBase64 != null && thumbnailBase64!.isNotEmpty);

  /// Czy produkt ma kod EAN do skanowania
  bool get hasEan => ean != null && ean!.isNotEmpty;

  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper to parse price (can be String or num from API)
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    return Product(
      id: json['id'] as int,
      clientId: json['clientId'] as int,
      nexoId: json['nexoId'] as String?,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      priceNetto: parsePrice(json['priceNetto']),
      priceBrutto: json['priceBrutto'] != null
          ? parsePrice(json['priceBrutto'])
          : null,
      vatRate: json['vatRate'] != null
          ? parsePrice(json['vatRate'])
          : null,
      unit: json['unit'] as String? ?? 'szt',
      ean: json['ean'] as String?,
      active: json['active'] as bool? ?? true,
      syncedAt: json['syncedAt'] != null
          ? DateTime.parse(json['syncedAt'] as String)
          : null,
      // Zdjęcia z cache
      thumbnailBase64: json['thumbnailBase64'] as String?,
      thumbnailSyncedAt: json['thumbnailSyncedAt'] != null
          ? DateTime.parse(json['thumbnailSyncedAt'] as String)
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
      'thumbnailBase64': thumbnailBase64,
      'thumbnailSyncedAt': thumbnailSyncedAt?.toIso8601String(),
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
      'thumbnail_base64': thumbnailBase64,
      'thumbnail_synced_at': thumbnailSyncedAt?.toIso8601String(),
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
      thumbnailBase64: map['thumbnail_base64'] as String?,
      thumbnailSyncedAt: map['thumbnail_synced_at'] != null
          ? DateTime.parse(map['thumbnail_synced_at'] as String)
          : null,
    );
  }
}
