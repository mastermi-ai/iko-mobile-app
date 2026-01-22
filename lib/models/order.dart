/// Pozycja zamówienia
///
/// UWAGA: Pole `quantityExtra` (gratisy) zostało USUNIĘTE zgodnie z wymaganiami klienta.
/// Ceny są "półkowe" (bazowe) - finalna kalkulacja rabatów następuje w nexo PRO.
class OrderItem {
  final String productCode;
  final String productName;
  final int productId;
  final double quantity;
  // quantityExtra USUNIĘTE - gratisy wyłączone przez klienta
  final double priceNetto;  // Cena półkowa (bazowa) - rabat obliczany w nexo
  final double? priceBrutto;
  final double? vatRate;
  // discount - wysyłamy do nexo, ale finalna kalkulacja w ERP
  final double? discount;
  final String? notes;
  final double total;

  OrderItem({
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
}

/// Zamówienie od Klienta (ZK w nexo PRO)
///
/// LOGIKA NOWYCH KLIENTÓW:
/// - Jeśli `customerId` == null → zamówienie dla NOWEGO klienta
/// - Dane nowego klienta (NIP, nazwa, adres) wpisywane w polu `notes`
/// - Biuro tworzy kartę kontrahenta w nexo przed przetworzeniem ZK
///
/// LOGIKA CEN:
/// - `totalNetto` = suma cen PÓŁKOWYCH (bazowych)
/// - Finalna kalkulacja rabatów następuje W NEXO po synchronizacji
class Order {
  final int? id;
  final int? localId;  // ID lokalne dla offline
  final int? customerId;  // null = nowy klient (dane w notes)
  final String? customerName;  // Dla wyświetlania
  final DateTime orderDate;
  final String status;  // pending, synced, processed, error
  /// Uwagi do zamówienia
  /// Dla NOWEGO klienta: "NIP: 1234567890, Nazwa: Firma XYZ, Adres: ..."
  final String? notes;
  final double totalNetto;  // Suma cen półkowych
  final double? totalBrutto;
  final List<OrderItem> items;
  final bool synced;
  final String? errorMessage;  // Błąd synchronizacji

  Order({
    this.id,
    this.localId,
    this.customerId,
    this.customerName,
    required this.orderDate,
    this.status = 'pending',
    this.notes,
    required this.totalNetto,
    this.totalBrutto,
    required this.items,
    this.synced = false,
    this.errorMessage,
  });

  /// Czy zamówienie jest dla nowego klienta (brak w bazie nexo)
  bool get isNewCustomer => customerId == null;

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'order_date': orderDate.toIso8601String(),
      'notes': notes,
      'total_netto': totalNetto,
      'total_brutto': totalBrutto,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  /// Tworzy kopię zamówienia z nowymi wartościami
  Order copyWith({
    int? id,
    int? localId,
    int? customerId,
    String? customerName,
    DateTime? orderDate,
    String? status,
    String? notes,
    double? totalNetto,
    double? totalBrutto,
    List<OrderItem>? items,
    bool? synced,
    String? errorMessage,
  }) {
    return Order(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      totalNetto: totalNetto ?? this.totalNetto,
      totalBrutto: totalBrutto ?? this.totalBrutto,
      items: items ?? this.items,
      synced: synced ?? this.synced,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
