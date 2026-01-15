import 'package:equatable/equatable.dart';
import 'product.dart';

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
