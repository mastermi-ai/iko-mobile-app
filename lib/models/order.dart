class OrderItem {
  final String productCode;
  final String productName;
  final int productId;
  final double quantity;
  final double? quantityExtra;
  final double priceNetto;
  final double? priceBrutto;
  final double? vatRate;
  final double? discount;
  final String? notes;
  final double total;

  OrderItem({
    required this.productCode,
    required this.productName,
    required this.productId,
    required this.quantity,
    this.quantityExtra,
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
      'quantity_extra': quantityExtra,
      'price_netto': priceNetto,
      'price_brutto': priceBrutto,
      'vat_rate': vatRate,
      'discount': discount,
      'notes': notes,
      'total': total,
    };
  }
}

class Order {
  final int? id;
  final int? customerId;
  final DateTime orderDate;
  final String status;
  final String? notes;
  final double totalNetto;
  final double? totalBrutto;
  final List<OrderItem> items;
  final bool synced;

  Order({
    this.id,
    this.customerId,
    required this.orderDate,
    this.status = 'pending',
    this.notes,
    required this.totalNetto,
    this.totalBrutto,
    required this.items,
    this.synced = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'order_date': orderDate.toIso8601String(),
      'notes': notes,
      'total_netto': totalNetto,
      'total_brutto': totalBrutto,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
