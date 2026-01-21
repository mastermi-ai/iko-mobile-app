import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/customer.dart';

/// Cart state holding items and selected customer
/// 
/// LOGIKA NOWYCH KLIENTÓW (wymaganie klienta):
/// - Jeśli `isNewCustomer` == true → zamówienie dla NOWEGO klienta
/// - `newCustomerData` zawiera NIP, nazwę, adres (wpisywane w uwagi ZK)
/// - Biuro tworzy kartę kontrahenta w nexo przed przetworzeniem
class CartState extends Equatable {
  final List<CartItem> items;
  final Customer? selectedCustomer;
  
  /// Czy zamówienie jest dla nowego klienta (nie z bazy)
  final bool isNewCustomer;
  /// Dane nowego klienta: "NIP: xxx, Nazwa: xxx, Adres: xxx"
  /// Wpisywane w pole UWAGI zamówienia (ZK) w nexo
  final String? newCustomerData;
  /// Dodatkowe uwagi do zamówienia
  final String? orderNotes;

  const CartState({
    this.items = const [],
    this.selectedCustomer,
    this.isNewCustomer = false,
    this.newCustomerData,
    this.orderNotes,
  });

  /// Total number of items in cart
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Total cart value (netto) - CENY PÓŁKOWE (bazowe)
  double get totalNetto => items.fold(0.0, (sum, item) => sum + item.totalNetto);

  /// Total cart value (brutto with VAT)
  double get totalBrutto => items.fold(0.0, (sum, item) => sum + item.totalBrutto);

  /// Check if cart is ready for checkout
  /// Można zamówić dla:
  /// 1. Wybranego klienta z bazy
  /// 2. LUB nowego klienta (z wypełnionymi danymi NIP/nazwa)
  bool get canCheckout {
    if (items.isEmpty) return false;
    
    // Istniejący klient wybrany
    if (selectedCustomer != null) return true;
    
    // Nowy klient - musi mieć wypełnione dane
    if (isNewCustomer && newCustomerData != null && newCustomerData!.trim().isNotEmpty) {
      return true;
    }
    
    return false;
  }
  
  /// Nazwa klienta do wyświetlenia
  String get customerDisplayName {
    if (selectedCustomer != null) return selectedCustomer!.name;
    if (isNewCustomer) return 'NOWY KLIENT';
    return 'Nie wybrano';
  }
  
  /// Pełne uwagi do zamówienia (łącznie z danymi nowego klienta)
  String? get fullOrderNotes {
    final parts = <String>[];
    
    // Dane nowego klienta jako pierwsza część uwag
    if (isNewCustomer && newCustomerData != null && newCustomerData!.isNotEmpty) {
      parts.add('[NOWY KLIENT]\n$newCustomerData');
    }
    
    // Dodatkowe uwagi
    if (orderNotes != null && orderNotes!.isNotEmpty) {
      parts.add(orderNotes!);
    }
    
    return parts.isEmpty ? null : parts.join('\n\n');
  }

  CartState copyWith({
    List<CartItem>? items,
    Customer? selectedCustomer,
    bool clearCustomer = false,
    bool? isNewCustomer,
    String? newCustomerData,
    bool clearNewCustomerData = false,
    String? orderNotes,
    bool clearOrderNotes = false,
  }) {
    return CartState(
      items: items ?? this.items,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      isNewCustomer: isNewCustomer ?? this.isNewCustomer,
      newCustomerData: clearNewCustomerData ? null : (newCustomerData ?? this.newCustomerData),
      orderNotes: clearOrderNotes ? null : (orderNotes ?? this.orderNotes),
    );
  }

  @override
  List<Object?> get props => [items, selectedCustomer, isNewCustomer, newCustomerData, orderNotes];
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

  /// Set customer for this order (istniejący klient z bazy)
  void selectCustomer(Customer customer) {
    emit(state.copyWith(
      selectedCustomer: customer,
      isNewCustomer: false,
      clearNewCustomerData: true,
    ));
  }

  /// Clear selected customer
  void clearCustomer() {
    emit(state.copyWith(clearCustomer: true));
  }

  /// Ustaw jako zamówienie dla NOWEGO klienta
  /// Dane klienta (NIP, nazwa, adres) wpisane w formularzu
  /// Trafią do pola UWAGI zamówienia ZK w nexo
  void setNewCustomer(String customerData) {
    emit(state.copyWith(
      isNewCustomer: true,
      newCustomerData: customerData,
      clearCustomer: true,  // Usuń wybranego klienta z bazy
    ));
  }
  
  /// Wyczyść dane nowego klienta
  void clearNewCustomer() {
    emit(state.copyWith(
      isNewCustomer: false,
      clearNewCustomerData: true,
    ));
  }
  
  /// Ustaw dodatkowe uwagi do zamówienia
  void setOrderNotes(String notes) {
    emit(state.copyWith(orderNotes: notes));
  }
  
  /// Wyczyść uwagi
  void clearOrderNotes() {
    emit(state.copyWith(clearOrderNotes: true));
  }

  /// Clear entire cart
  void clearCart() {
    emit(const CartState());
  }

  /// Get current cart for order creation
  CartState getCurrentCart() => state;
}
