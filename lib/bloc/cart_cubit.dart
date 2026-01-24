import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/customer.dart';

/// Multi-koszyk: Stan koszyka obsługujący wielu klientów jednocześnie
///
/// LOGIKA:
/// - Każdy klient ma swój osobny koszyk produktów
/// - Można przełączać się między klientami
/// - Zamówienie tworzone jest dla wszystkich klientów naraz
/// - Opcjonalnie można obsłużyć "nowego klienta" (dane w uwagach)
class CartState extends Equatable {
  /// Lista koszyków per klient
  final List<CustomerCart> customerCarts;

  /// Aktualnie wybrany klient (do którego dodajemy produkty)
  final Customer? activeCustomer;

  /// Czy aktywny jest tryb "nowy klient" (nie z bazy)
  final bool isNewCustomer;

  /// Dane nowego klienta (NIP, nazwa, adres - do uwag ZK)
  final String? newCustomerData;

  /// Produkty dla nowego klienta
  final List<CartItem> newCustomerItems;

  const CartState({
    this.customerCarts = const [],
    this.activeCustomer,
    this.isNewCustomer = false,
    this.newCustomerData,
    this.newCustomerItems = const [],
  });

  /// Całkowita liczba produktów we wszystkich koszykach
  int get totalItemCount {
    int count = customerCarts.fold(0, (sum, cart) => sum + cart.itemCount);
    count += newCustomerItems.fold(0, (sum, item) => sum + item.quantity);
    return count;
  }

  /// Liczba produktów w aktywnym koszyku (aktualny klient)
  int get activeItemCount {
    if (isNewCustomer) {
      return newCustomerItems.fold(0, (sum, item) => sum + item.quantity);
    }
    if (activeCustomer == null) return 0;
    final cart = customerCarts.firstWhere(
      (c) => c.customer.id == activeCustomer!.id,
      orElse: () => CustomerCart(customer: activeCustomer!, items: []),
    );
    return cart.itemCount;
  }

  /// Produkty aktywnego klienta
  List<CartItem> get activeItems {
    if (isNewCustomer) {
      return newCustomerItems;
    }
    if (activeCustomer == null) return [];
    final cart = customerCarts.firstWhere(
      (c) => c.customer.id == activeCustomer!.id,
      orElse: () => CustomerCart(customer: activeCustomer!, items: []),
    );
    return cart.items;
  }

  /// Całkowita wartość netto wszystkich koszyków
  double get totalNetto {
    double total = customerCarts.fold(0.0, (sum, cart) => sum + cart.totalNetto);
    total += newCustomerItems.fold(0.0, (sum, item) => sum + item.totalNetto);
    return total;
  }

  /// Całkowita wartość brutto wszystkich koszyków
  double get totalBrutto {
    double total = customerCarts.fold(0.0, (sum, cart) => sum + cart.totalBrutto);
    total += newCustomerItems.fold(0.0, (sum, item) => sum + item.totalBrutto);
    return total;
  }

  /// Liczba klientów w koszykach
  int get customerCount {
    int count = customerCarts.where((c) => c.items.isNotEmpty).length;
    if (isNewCustomer && newCustomerItems.isNotEmpty) count++;
    return count;
  }

  /// Czy są jakiekolwiek produkty do zamówienia
  bool get hasItems => totalItemCount > 0;

  /// Czy można złożyć zamówienie (są produkty i klienci)
  bool get canCheckout {
    // Sprawdź czy są niepuste koszyki
    final hasCustomerItems = customerCarts.any((c) => c.items.isNotEmpty);
    final hasNewCustomerItems = isNewCustomer && newCustomerItems.isNotEmpty && newCustomerData != null;
    return hasCustomerItems || hasNewCustomerItems;
  }

  /// Nazwa aktywnego klienta do wyświetlenia
  String get activeCustomerName {
    if (isNewCustomer) return 'NOWY KLIENT';
    if (activeCustomer != null) return activeCustomer!.shortName ?? activeCustomer!.name;
    return 'Nie wybrano';
  }

  /// Liczba aktywnych koszyków (z produktami)
  int get activeCartsCount {
    int count = customerCarts.where((c) => c.items.isNotEmpty).length;
    if (newCustomerItems.isNotEmpty) count++;
    return count;
  }

  CartState copyWith({
    List<CustomerCart>? customerCarts,
    Customer? activeCustomer,
    bool clearActiveCustomer = false,
    bool? isNewCustomer,
    String? newCustomerData,
    bool clearNewCustomerData = false,
    List<CartItem>? newCustomerItems,
  }) {
    return CartState(
      customerCarts: customerCarts ?? this.customerCarts,
      activeCustomer: clearActiveCustomer ? null : (activeCustomer ?? this.activeCustomer),
      isNewCustomer: isNewCustomer ?? this.isNewCustomer,
      newCustomerData: clearNewCustomerData ? null : (newCustomerData ?? this.newCustomerData),
      newCustomerItems: newCustomerItems ?? this.newCustomerItems,
    );
  }

  // =====================================================
  // LEGACY GETTERS (dla kompatybilności wstecznej)
  // =====================================================

  /// Produkty aktywnego klienta (legacy)
  List<CartItem> get items => activeItems;

  /// Liczba produktów aktywnego klienta (legacy)
  int get itemCount => totalItemCount;

  /// Wybrany klient (legacy)
  Customer? get selectedCustomer => activeCustomer;

  /// Nazwa klienta do wyświetlenia (legacy)
  String get customerDisplayName => activeCustomerName;

  /// Uwagi do zamówienia (legacy - tylko dla nowego klienta)
  String? get fullOrderNotes {
    if (isNewCustomer && newCustomerData != null && newCustomerData!.isNotEmpty) {
      return '[NOWY KLIENT]\n$newCustomerData';
    }
    return null;
  }

  @override
  List<Object?> get props => [
    customerCarts,
    activeCustomer,
    isNewCustomer,
    newCustomerData,
    newCustomerItems,
  ];
}

/// Cart Cubit - zarządzanie multi-koszykiem
class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  /// Wybierz klienta jako aktywnego (do dodawania produktów)
  void selectCustomer(Customer customer) {
    // Sprawdź czy klient już ma koszyk
    final existingIndex = state.customerCarts.indexWhere(
      (c) => c.customer.id == customer.id,
    );

    if (existingIndex < 0) {
      // Dodaj nowy pusty koszyk dla tego klienta
      final carts = List<CustomerCart>.from(state.customerCarts);
      carts.add(CustomerCart(customer: customer, items: []));
      emit(state.copyWith(
        customerCarts: carts,
        activeCustomer: customer,
        isNewCustomer: false,
        clearNewCustomerData: true,
      ));
    } else {
      emit(state.copyWith(
        activeCustomer: customer,
        isNewCustomer: false,
      ));
    }
  }

  /// Dodaj produkt do koszyka aktywnego klienta
  void addProduct(Product product, {int quantity = 1}) {
    if (state.isNewCustomer) {
      _addProductToNewCustomer(product, quantity);
      return;
    }

    if (state.activeCustomer == null) {
      return;
    }

    final carts = List<CustomerCart>.from(state.customerCarts);
    final customerIndex = carts.indexWhere(
      (c) => c.customer.id == state.activeCustomer!.id,
    );

    if (customerIndex < 0) {
      // Utwórz nowy koszyk dla klienta
      carts.add(CustomerCart(
        customer: state.activeCustomer!,
        items: [CartItem(product: product, quantity: quantity)],
      ));
    } else {
      // Dodaj do istniejącego koszyka
      final cart = carts[customerIndex];
      final items = List<CartItem>.from(cart.items);
      final existingIndex = items.indexWhere((i) => i.product.id == product.id);

      if (existingIndex >= 0) {
        items[existingIndex] = items[existingIndex].copyWith(
          quantity: items[existingIndex].quantity + quantity,
        );
      } else {
        items.add(CartItem(product: product, quantity: quantity));
      }

      carts[customerIndex] = cart.copyWith(items: items);
    }

    emit(state.copyWith(customerCarts: carts));
  }

  void _addProductToNewCustomer(Product product, int quantity) {
    final items = List<CartItem>.from(state.newCustomerItems);
    final existingIndex = items.indexWhere((i) => i.product.id == product.id);

    if (existingIndex >= 0) {
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + quantity,
      );
    } else {
      items.add(CartItem(product: product, quantity: quantity));
    }

    emit(state.copyWith(newCustomerItems: items));
  }

  /// Zmień ilość produktu w koszyku klienta
  void updateQuantity(Product product, int newQuantity, {Customer? customer}) {
    final targetCustomer = customer ?? state.activeCustomer;

    if (state.isNewCustomer && customer == null) {
      _updateNewCustomerQuantity(product, newQuantity);
      return;
    }

    if (targetCustomer == null) return;

    if (newQuantity <= 0) {
      removeProduct(product, customer: targetCustomer);
      return;
    }

    final carts = List<CustomerCart>.from(state.customerCarts);
    final customerIndex = carts.indexWhere(
      (c) => c.customer.id == targetCustomer.id,
    );

    if (customerIndex < 0) return;

    final cart = carts[customerIndex];
    final items = List<CartItem>.from(cart.items);
    final productIndex = items.indexWhere((i) => i.product.id == product.id);

    if (productIndex >= 0) {
      items[productIndex] = items[productIndex].copyWith(quantity: newQuantity);
      carts[customerIndex] = cart.copyWith(items: items);
      emit(state.copyWith(customerCarts: carts));
    }
  }

  void _updateNewCustomerQuantity(Product product, int newQuantity) {
    if (newQuantity <= 0) {
      removeProductFromNewCustomer(product);
      return;
    }

    final items = List<CartItem>.from(state.newCustomerItems);
    final productIndex = items.indexWhere((i) => i.product.id == product.id);

    if (productIndex >= 0) {
      items[productIndex] = items[productIndex].copyWith(quantity: newQuantity);
      emit(state.copyWith(newCustomerItems: items));
    }
  }

  /// Usuń produkt z koszyka klienta
  void removeProduct(Product product, {Customer? customer}) {
    final targetCustomer = customer ?? state.activeCustomer;

    if (state.isNewCustomer && customer == null) {
      removeProductFromNewCustomer(product);
      return;
    }

    if (targetCustomer == null) return;

    final carts = List<CustomerCart>.from(state.customerCarts);
    final customerIndex = carts.indexWhere(
      (c) => c.customer.id == targetCustomer.id,
    );

    if (customerIndex < 0) return;

    final cart = carts[customerIndex];
    final items = cart.items.where((i) => i.product.id != product.id).toList();
    carts[customerIndex] = cart.copyWith(items: items);

    emit(state.copyWith(customerCarts: carts));
  }

  void removeProductFromNewCustomer(Product product) {
    final items = state.newCustomerItems.where((i) => i.product.id != product.id).toList();
    emit(state.copyWith(newCustomerItems: items));
  }

  /// Usuń cały koszyk klienta
  void removeCustomerCart(Customer customer) {
    final carts = state.customerCarts.where(
      (c) => c.customer.id != customer.id,
    ).toList();

    emit(state.copyWith(
      customerCarts: carts,
      activeCustomer: state.activeCustomer?.id == customer.id ? null : state.activeCustomer,
      clearActiveCustomer: state.activeCustomer?.id == customer.id,
    ));
  }

  /// Ustaw tryb "nowy klient"
  void setNewCustomer(String customerData) {
    emit(state.copyWith(
      isNewCustomer: true,
      newCustomerData: customerData,
      clearActiveCustomer: true,
    ));
  }

  /// Wyczyść dane nowego klienta
  void clearNewCustomer() {
    emit(state.copyWith(
      isNewCustomer: false,
      clearNewCustomerData: true,
      newCustomerItems: [],
    ));
  }

  /// Wyczyść wybranego klienta
  void clearCustomer() {
    emit(state.copyWith(clearActiveCustomer: true));
  }

  /// Wyczyść cały koszyk (wszystkich klientów)
  void clearCart() {
    emit(const CartState());
  }

  /// Wyczyść koszyk tylko dla aktywnego klienta
  void clearActiveCustomerCart() {
    if (state.isNewCustomer) {
      emit(state.copyWith(newCustomerItems: []));
      return;
    }

    if (state.activeCustomer == null) return;

    final carts = List<CustomerCart>.from(state.customerCarts);
    final customerIndex = carts.indexWhere(
      (c) => c.customer.id == state.activeCustomer!.id,
    );

    if (customerIndex >= 0) {
      carts[customerIndex] = carts[customerIndex].copyWith(items: []);
      emit(state.copyWith(customerCarts: carts));
    }
  }

  /// Pobierz koszyk dla konkretnego klienta
  CustomerCart? getCartForCustomer(Customer customer) {
    try {
      return state.customerCarts.firstWhere(
        (c) => c.customer.id == customer.id,
      );
    } catch (_) {
      return null;
    }
  }

  /// Legacy: getCurrentCart dla kompatybilności
  CartState getCurrentCart() => state;

  /// Czy zmieniany jest klient z niepustym koszykiem
  bool get hasItemsForDifferentCustomer {
    return state.customerCarts.any((c) => c.items.isNotEmpty);
  }

  /// Pobierz wszystkie niepuste koszyki (do tworzenia zamówień)
  List<CustomerCart> getActiveCustomerCarts() {
    return state.customerCarts.where((c) => c.items.isNotEmpty).toList();
  }

  /// Ustaw uwagi do zamówienia (legacy)
  void setOrderNotes(String notes) {
    // Uwagi są teraz tylko dla nowego klienta
    if (state.isNewCustomer) {
      emit(state.copyWith(newCustomerData: notes));
    }
  }

  /// Wyczyść uwagi (legacy)
  void clearOrderNotes() {
    // Nic nie rób - uwagi są częścią danych nowego klienta
  }
}
