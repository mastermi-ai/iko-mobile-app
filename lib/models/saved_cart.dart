import 'dart:convert';
import 'cart_item.dart';
import 'product.dart';
import 'customer.dart';

/// Saved cart item for storage
class SavedCartItem {
  final int productId;
  final String productCode;
  final String productName;
  final double priceNetto;
  final double? priceBrutto;
  final double? vatRate;
  final String unit;
  final int quantity;

  SavedCartItem({
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.priceNetto,
    this.priceBrutto,
    this.vatRate,
    required this.unit,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_code': productCode,
      'product_name': productName,
      'price_netto': priceNetto,
      'price_brutto': priceBrutto,
      'vat_rate': vatRate,
      'unit': unit,
      'quantity': quantity,
    };
  }

  factory SavedCartItem.fromJson(Map<String, dynamic> json) {
    return SavedCartItem(
      productId: json['product_id'] as int,
      productCode: json['product_code'] as String,
      productName: json['product_name'] as String,
      priceNetto: (json['price_netto'] as num).toDouble(),
      priceBrutto: json['price_brutto'] != null
          ? (json['price_brutto'] as num).toDouble()
          : null,
      vatRate: json['vat_rate'] != null
          ? (json['vat_rate'] as num).toDouble()
          : null,
      unit: json['unit'] as String? ?? 'szt',
      quantity: json['quantity'] as int,
    );
  }

  /// Create from CartItem
  factory SavedCartItem.fromCartItem(CartItem cartItem) {
    return SavedCartItem(
      productId: cartItem.product.id!,
      productCode: cartItem.product.code,
      productName: cartItem.product.name,
      priceNetto: cartItem.product.priceNetto,
      priceBrutto: cartItem.product.priceBrutto,
      vatRate: cartItem.product.vatRate,
      unit: cartItem.product.unit,
      quantity: cartItem.quantity,
    );
  }

  /// Convert to Product (for loading back to cart)
  Product toProduct() {
    return Product(
      id: productId,
      clientId: 0, // Will be resolved when loading
      code: productCode,
      name: productName,
      priceNetto: priceNetto,
      priceBrutto: priceBrutto,
      vatRate: vatRate,
      unit: unit,
      active: true,
    );
  }
}

/// Saved cart (schowek)
class SavedCart {
  final int? id;
  final String name;
  final int? customerId;
  final String? customerName;
  final List<SavedCartItem> items;
  final double totalNetto;
  final double? totalBrutto;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SavedCart({
    this.id,
    required this.name,
    this.customerId,
    this.customerName,
    required this.items,
    required this.totalNetto,
    this.totalBrutto,
    required this.createdAt,
    this.updatedAt,
  });

  /// Total items count
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Convert to database map
  Map<String, dynamic> toDatabase() {
    return {
      'name': name,
      'customer_id': customerId,
      'customer_name': customerName,
      'items_json': jsonEncode(items.map((i) => i.toJson()).toList()),
      'total_netto': totalNetto,
      'total_brutto': totalBrutto,
      'created_at': createdAt.toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  /// Create from database map
  factory SavedCart.fromDatabase(Map<String, dynamic> map) {
    List<SavedCartItem> parsedItems = [];

    if (map['items_json'] != null) {
      try {
        final itemsList = jsonDecode(map['items_json'] as String) as List;
        parsedItems = itemsList
            .map((item) => SavedCartItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // If parsing fails, items will be empty
      }
    }

    return SavedCart(
      id: map['id'] as int?,
      name: map['name'] as String,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
      items: parsedItems,
      totalNetto: (map['total_netto'] as num).toDouble(),
      totalBrutto: map['total_brutto'] != null
          ? (map['total_brutto'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Create from current cart state
  factory SavedCart.fromCartState({
    required String name,
    required List<CartItem> items,
    Customer? customer,
    required double totalNetto,
    double? totalBrutto,
  }) {
    return SavedCart(
      name: name,
      customerId: customer?.id,
      customerName: customer?.name,
      items: items.map((ci) => SavedCartItem.fromCartItem(ci)).toList(),
      totalNetto: totalNetto,
      totalBrutto: totalBrutto,
      createdAt: DateTime.now(),
    );
  }

  SavedCart copyWith({
    int? id,
    String? name,
    int? customerId,
    String? customerName,
    List<SavedCartItem>? items,
    double? totalNetto,
    double? totalBrutto,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedCart(
      id: id ?? this.id,
      name: name ?? this.name,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      totalNetto: totalNetto ?? this.totalNetto,
      totalBrutto: totalBrutto ?? this.totalBrutto,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
