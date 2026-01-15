import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/customer.dart';

/// Cart state holding items and selected customer
class CartState extends Equatable {
  final List<CartItem> items;
  final Customer? selectedCustomer;

  const CartState({
    this.items = const [],
    this.selectedCustomer,
  });

  /// Total number of items in cart
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Total cart value (netto)
  double get totalNetto => items.fold(0.0, (sum, item) => sum + item.totalNetto);

  /// Total cart value (brutto with VAT)
  double get totalBrutto => items.fold(0.0, (sum, item) => sum + item.totalBrutto);

  /// Check if cart is ready for checkout (has items and customer)
  bool get canCheckout => items.isNotEmpty && selectedCustomer != null;

  CartState copyWith({
    List<CartItem>? items,
    Customer? selectedCustomer,
    bool clearCustomer = false,
  }) {
    return CartState(
      items: items ?? this.items,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
    );
  }

  @override
  List<Object?> get props => [items, selectedCustomer];
}

/// Cart Cubit for managing shopping cart state
class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  /// Add product to cart or increase quantity if already exists
  void addProduct(Product product, {int quantity = 1}) {
    final items = List<CartItem>.from(state.items);
    final existingIndex = items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      // Product already in cart - increase quantity
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + quantity,
      );
    } else {
      // New product - add to cart
      items.add(CartItem(product: product, quantity: quantity));
    }

    emit(state.copyWith(items: items));
  }

  /// Update quantity for specific cart item
  void updateQuantity(Product product, int newQuantity) {
    if (newQuantity <= 0) {
      removeProduct(product);
      return;
    }

    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      items[index] = items[index].copyWith(quantity: newQuantity);
      emit(state.copyWith(items: items));
    }
  }

  /// Remove product from cart
  void removeProduct(Product product) {
    final items = state.items.where((item) => item.product.id != product.id).toList();
    emit(state.copyWith(items: items));
  }

  /// Set customer for this order
  void selectCustomer(Customer customer) {
    emit(state.copyWith(selectedCustomer: customer));
  }

  /// Clear selected customer
  void clearCustomer() {
    emit(state.copyWith(clearCustomer: true));
  }

  /// Clear entire cart
  void clearCart() {
    emit(const CartState());
  }

  /// Get current cart for order creation
  CartState getCurrentCart() => state;
}
