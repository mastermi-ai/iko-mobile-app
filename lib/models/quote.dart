import 'dart:convert';

/// Pozycja oferty
///
/// UWAGA: Pole `quantityExtra` (gratisy) zostało USUNIĘTE zgodnie z wymaganiami klienta.
/// Ceny są "półkowe" (bazowe) - używane do komunikacji z klientem.
/// Oferty w IKO to "lekka wersja" - PDF/email, nie formalny dokument w nexo.
class QuoteItem {
  final String productCode;
  final String productName;
  final int productId;
  final double quantity;
  // quantityExtra USUNIĘTE - gratisy wyłączone przez klienta
  final double priceNetto;  // Cena półkowa (bazowa)
  final double? priceBrutto;
  final double? vatRate;
  final double? discount;
  final String? notes;
  final double total;

  QuoteItem({
    required this.productCode,
    required this.productName,
    required this.productId,
    required this.quantity,
    required this.priceNetto,
    this.priceBrutto,
    this.vatRate,
    this.discount,
    this.notes,
    required this.total,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_code': productCode,
      'product_name': productName,
      'quantity': quantity,
      'price_netto': priceNetto,  // Cena półkowa
      'price_brutto': priceBrutto,
      'vat_rate': vatRate,
      'discount': discount,
      'notes': notes,
      'total': total,
    };
  }

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      productId: json['product_id'] as int,
      productCode: json['product_code'] as String,
      productName: json['product_name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      priceNetto: (json['price_netto'] as num).toDouble(),
      priceBrutto: json['price_brutto'] != null
          ? (json['price_brutto'] as num).toDouble()
          : null,
      vatRate: json['vat_rate'] != null
          ? (json['vat_rate'] as num).toDouble()
          : null,
      discount: json['discount'] != null
          ? (json['discount'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
      total: (json['total'] as num).toDouble(),
    );
  }
}

/// Quote (Oferta) - similar to Order but for price quotes
class Quote {
  final int? id;
  final int? localId;
  final int? customerId;
  final String? customerName;
  final DateTime quoteDate;
  final DateTime? validUntil;
  final String status; // draft, sent, accepted, rejected, expired, converted
  final String? notes;
  final double totalNetto;
  final double? totalBrutto;
  final List<QuoteItem> items;
  final bool synced;
  final DateTime? createdAt;

  Quote({
    this.id,
    this.localId,
    this.customerId,
    this.customerName,
    required this.quoteDate,
    this.validUntil,
    this.status = 'draft',
    this.notes,
    required this.totalNetto,
    this.totalBrutto,
    required this.items,
    this.synced = false,
    this.createdAt,
  });

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'quote_date': quoteDate.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'notes': notes,
      'total_netto': totalNetto,
      'total_brutto': totalBrutto,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  /// Create from API JSON response
  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as int,
      customerId: json['customerId'] as int?,
      customerName: json['customer']?['name'] as String?,
      quoteDate: DateTime.parse(json['quoteDate'] as String),
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'] as String)
          : null,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      totalNetto: (json['totalNetto'] as num).toDouble(),
      totalBrutto: json['totalBrutto'] != null
          ? (json['totalBrutto'] as num).toDouble()
          : null,
      items: (json['items'] as List?)
          ?.map((item) => QuoteItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      synced: true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Convert to database map for local storage
  Map<String, dynamic> toDatabase() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'quote_date': quoteDate.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'status': status,
      'notes': notes,
      'total_netto': totalNetto,
      'total_brutto': totalBrutto,
      'items_json': jsonEncode(items.map((i) => i.toJson()).toList()),
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  /// Create from local database map
  factory Quote.fromDatabase(Map<String, dynamic> map) {
    List<QuoteItem> parsedItems = [];

    if (map['items_json'] != null) {
      try {
        final itemsList = jsonDecode(map['items_json'] as String) as List;
        parsedItems = itemsList
            .map((item) => QuoteItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // If parsing fails, items will be empty
      }
    }

    return Quote(
      localId: map['local_id'] as int?,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
      quoteDate: DateTime.parse(map['quote_date'] as String),
      validUntil: map['valid_until'] != null
          ? DateTime.parse(map['valid_until'] as String)
          : null,
      status: map['status'] as String? ?? 'draft',
      notes: map['notes'] as String?,
      totalNetto: (map['total_netto'] as num).toDouble(),
      totalBrutto: map['total_brutto'] != null
          ? (map['total_brutto'] as num).toDouble()
          : null,
      items: parsedItems,
      synced: (map['synced'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Check if quote is still valid
  bool get isValid {
    if (validUntil == null) return true;
    return DateTime.now().isBefore(validUntil!);
  }

  /// Get status display name in Polish
  String get statusDisplayName {
    switch (status) {
      case 'draft':
        return 'Szkic';
      case 'sent':
        return 'Wysłana';
      case 'accepted':
        return 'Zaakceptowana';
      case 'rejected':
        return 'Odrzucona';
      case 'expired':
        return 'Wygasła';
      case 'converted':
        return 'Przekonwertowana';
      default:
        return status;
    }
  }

  /// Copy with new values
  Quote copyWith({
    int? id,
    int? localId,
    int? customerId,
    String? customerName,
    DateTime? quoteDate,
    DateTime? validUntil,
    String? status,
    String? notes,
    double? totalNetto,
    double? totalBrutto,
    List<QuoteItem>? items,
    bool? synced,
    DateTime? createdAt,
  }) {
    return Quote(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      quoteDate: quoteDate ?? this.quoteDate,
      validUntil: validUntil ?? this.validUntil,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      totalNetto: totalNetto ?? this.totalNetto,
      totalBrutto: totalBrutto ?? this.totalBrutto,
      items: items ?? this.items,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
