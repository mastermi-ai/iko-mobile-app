import 'package:equatable/equatable.dart';
import 'product.dart';
import 'customer.dart';

/// Cart item holding product and quantity
class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  /// Calculate total price for this item (netto)
  double get totalNetto => product.priceNetto * quantity;

  /// Calculate total price including VAT
  double get totalBrutto {
    if (product.priceBrutto != null) {
      return product.priceBrutto! * quantity;
    }
    // Calculate from netto + VAT if brutto not available
    final vatMultiplier = 1 + ((product.vatRate ?? 0) / 100);
    return totalNetto * vatMultiplier;
  }

  /// Create copy with new quantity
  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product.id, quantity];
}

/// Koszyk dla jednego klienta (multi-koszyk)
class CustomerCart extends Equatable {
  final Customer customer;
  final List<CartItem> items;

  const CustomerCart({
    required this.customer,
    this.items = const [],
  });

  /// Total number of items in this customer's cart
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Total value (netto)
  double get totalNetto => items.fold(0.0, (sum, item) => sum + item.totalNetto);

  /// Total value (brutto)
  double get totalBrutto => items.fold(0.0, (sum, item) => sum + item.totalBrutto);

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Copy with modifications
  CustomerCart copyWith({
    Customer? customer,
    List<CartItem>? items,
  }) {
    return CustomerCart(
      customer: customer ?? this.customer,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [customer.id, items];
}
