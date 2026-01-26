import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cart_cubit.dart';
import '../models/cart_item.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';
import '../widgets/app_notification.dart';
import 'customers_list_screen.dart';

/// Multi-koszyk - ekran z koszykami wielu klientów
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koszyk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearAllDialog(context),
            tooltip: 'Wyczyść wszystko',
          ),
        ],
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (!state.hasItems) {
            return _buildEmptyCart(context);
          }

          return Column(
            children: [
              // Główna lista koszyków klientów
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Koszyki istniejących klientów
                      ...state.customerCarts
                          .where((cart) => cart.items.isNotEmpty)
                          .map((cart) => _CustomerCartSection(
                                customerCart: cart,
                                isActive: state.activeCustomer?.id == cart.customer.id,
                              )),

                      // Koszyk nowego klienta (jeśli są produkty)
                      if (state.newCustomerItems.isNotEmpty)
                        _NewCustomerCartSection(
                          items: state.newCustomerItems,
                          customerData: state.newCustomerData,
                        ),

                      // Przycisk dodania kolejnego klienta
                      _AddCustomerButton(),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Podsumowanie i przycisk zamówienia
              _CartSummary(state: state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Koszyk jest pusty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Wybierz klienta i dodaj produkty',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CustomersListScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Wybierz klienta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Wyczyść wszystko'),
        content: const Text('Czy na pewno chcesz usunąć wszystkie koszyki?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              context.read<CartCubit>().clearCart();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Wyczyść', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Sekcja koszyka dla jednego klienta
class _CustomerCartSection extends StatelessWidget {
  final CustomerCart customerCart;
  final bool isActive;

  const _CustomerCartSection({
    required this.customerCart,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.blue[400]! : Colors.grey[300]!,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek klienta
          _CustomerHeader(
            customer: customerCart.customer,
            itemCount: customerCart.itemCount,
            totalBrutto: customerCart.totalBrutto,
            isActive: isActive,
          ),

          // Lista produktów
          ...customerCart.items.map((item) => _CartItemRow(
                item: item,
                customer: customerCart.customer,
              )),

          // Usuń koszyk klienta
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    context.read<CartCubit>().removeCustomerCart(customerCart.customer);
                  },
                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
                  label: Text('Usuń koszyk', style: TextStyle(color: Colors.red[400])),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nagłówek klienta w koszyku
class _CustomerHeader extends StatelessWidget {
  final Customer customer;
  final int itemCount;
  final double totalBrutto;
  final bool isActive;

  const _CustomerHeader({
    required this.customer,
    required this.itemCount,
    required this.totalBrutto,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue[50] : Colors.green[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(11),
          topRight: Radius.circular(11),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.shortName ?? customer.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$itemCount szt. • ${totalBrutto.toStringAsFixed(2)} zł brutto',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          // Przycisk zmiany/edycji
          ElevatedButton.icon(
            onPressed: () {
              context.read<CartCubit>().selectCustomer(customer);
              AppNotification.info(context, 'Aktywny klient: ${customer.shortName ?? customer.name}');
            },
            icon: Icon(isActive ? Icons.edit : Icons.touch_app, size: 16),
            label: Text(isActive ? 'Zmień' : 'Wybierz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.blue[700] : Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wiersz produktu w koszyku
class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final Customer? customer;

  const _CartItemRow({
    required this.item,
    this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Ikona produktu
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.inventory_2, size: 20, color: Colors.grey),
          ),
          const SizedBox(width: 12),

          // Nazwa i cena
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.product.priceNetto.toStringAsFixed(2)} zł/szt',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Razem: ${item.totalNetto.toStringAsFixed(2)} zł',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),

          // Kontrola ilości
          _QuantityControl(item: item, customer: customer),

          // Usuń
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red[400], size: 22),
            onPressed: () {
              context.read<CartCubit>().removeProduct(item.product, customer: customer);
            },
          ),
        ],
      ),
    );
  }
}

/// Kontrola ilości produktu
class _QuantityControl extends StatefulWidget {
  final CartItem item;
  final Customer? customer;

  const _QuantityControl({
    required this.item,
    this.customer,
  });

  @override
  State<_QuantityControl> createState() => _QuantityControlState();
}

class _QuantityControlState extends State<_QuantityControl> {
  void _showQuantityDialog() {
    final controller = TextEditingController(text: '${widget.item.quantity}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Podaj ilość'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Ilość',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => _submitQuantity(controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => _submitQuantity(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _submitQuantity(String value) {
    final quantity = int.tryParse(value);
    if (quantity != null && quantity > 0) {
      context.read<CartCubit>().updateQuantity(
            widget.item.product,
            quantity,
            customer: widget.customer,
          );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Przycisk minus - powiększone pole dotykowe 48x48
          InkWell(
            onTap: () {
              context.read<CartCubit>().updateQuantity(
                    widget.item.product,
                    widget.item.quantity - 1,
                    customer: widget.customer,
                  );
            },
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: const Icon(Icons.remove, size: 24),
            ),
          ),
          // Ilość - klikalna do ręcznego wpisania
          InkWell(
            onTap: _showQuantityDialog,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.symmetric(
                  vertical: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Text(
                '${widget.item.quantity}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Przycisk plus - powiększone pole dotykowe 48x48
          InkWell(
            onTap: () {
              context.read<CartCubit>().updateQuantity(
                    widget.item.product,
                    widget.item.quantity + 1,
                    customer: widget.customer,
                  );
            },
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: const Icon(Icons.add, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sekcja dla nowego klienta
class _NewCustomerCartSection extends StatelessWidget {
  final List<CartItem> items;
  final String? customerData;

  const _NewCustomerCartSection({
    required this.items,
    this.customerData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek nowego klienta
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person_add, color: Colors.orange[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NOWY KLIENT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      if (customerData != null)
                        Text(
                          customerData!.split('\n').first,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showNewCustomerDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('Edytuj dane'),
                ),
              ],
            ),
          ),

          // Lista produktów
          ...items.map((item) => _CartItemRow(item: item, customer: null)),

          // Usuń koszyk
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    context.read<CartCubit>().clearNewCustomer();
                  },
                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
                  label: Text('Usuń koszyk', style: TextStyle(color: Colors.red[400])),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNewCustomerDialog(BuildContext context) {
    final nipController = TextEditingController();
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    if (customerData != null) {
      final lines = customerData!.split('\n');
      for (final line in lines) {
        if (line.startsWith('NIP:')) {
          nipController.text = line.replaceFirst('NIP:', '').trim();
        } else if (line.startsWith('Nazwa:')) {
          nameController.text = line.replaceFirst('Nazwa:', '').trim();
        } else if (line.startsWith('Adres:')) {
          addressController.text = line.replaceFirst('Adres:', '').trim();
        }
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Colors.orange),
            SizedBox(width: 8),
            Text('Dane nowego klienta'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nipController,
                decoration: const InputDecoration(
                  labelText: 'NIP *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa firmy *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Adres',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              final nip = nipController.text.trim();
              final name = nameController.text.trim();
              final address = addressController.text.trim();

              if (nip.isEmpty || name.isEmpty) {
                AppNotification.error(context, 'NIP i Nazwa są wymagane');
                return;
              }

              final data = [
                'NIP: $nip',
                'Nazwa: $name',
                if (address.isNotEmpty) 'Adres: $address',
              ].join('\n');

              context.read<CartCubit>().setNewCustomer(data);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }
}

/// Przycisk dodania kolejnego klienta
class _AddCustomerButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CustomersListScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Dodaj klienta z bazy'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.blue[700]!),
                foregroundColor: Colors.blue[700],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showNewCustomerDialog(context),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Nowy klient'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.orange[700]!),
                foregroundColor: Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewCustomerDialog(BuildContext context) {
    final nipController = TextEditingController();
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Colors.orange),
            SizedBox(width: 8),
            Text('Nowy klient'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dane klienta trafią do uwag zamówienia',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nipController,
                decoration: const InputDecoration(
                  labelText: 'NIP *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa firmy *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Adres',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              final nip = nipController.text.trim();
              final name = nameController.text.trim();
              final address = addressController.text.trim();

              if (nip.isEmpty || name.isEmpty) {
                AppNotification.error(context, 'NIP i Nazwa są wymagane');
                return;
              }

              final data = [
                'NIP: $nip',
                'Nazwa: $name',
                if (address.isNotEmpty) 'Adres: $address',
              ].join('\n');

              context.read<CartCubit>().setNewCustomer(data);
              Navigator.of(dialogContext).pop();

              AppNotification.success(context, 'Nowy klient aktywny');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }
}

/// Podsumowanie koszyka i przycisk zamówienia
class _CartSummary extends StatelessWidget {
  final CartState state;

  const _CartSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Podsumowanie
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${state.customerCount} klient(ów) • ${state.totalItemCount} szt',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  '${state.totalNetto.toStringAsFixed(2)} zł netto',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Razem brutto:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${state.totalBrutto.toStringAsFixed(2)} zł',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Przycisk zamówienia
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.canCheckout
                    ? () => _createOrders(context)
                    : null,
                icon: const Icon(Icons.check_circle, size: 24),
                label: Text(
                  state.customerCount > 1
                      ? 'Utwórz ${state.customerCount} zamówienia'
                      : 'Utwórz zamówienie',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey[300],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createOrders(BuildContext context) async {
    final cartCubit = context.read<CartCubit>();
    final activeCarts = cartCubit.getActiveCustomerCarts();
    final state = cartCubit.state;

    // Pokaż dialog ładowania
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    int successCount = 0;
    int errorCount = 0;

    try {
      final apiService = ApiService();
      await apiService.loadToken();

      // Utwórz zamówienia dla każdego klienta
      for (final customerCart in activeCarts) {
        try {
          final order = Order(
            customerId: customerCart.customer.id,
            customerName: customerCart.customer.name,
            orderDate: DateTime.now(),
            totalNetto: customerCart.totalNetto,
            totalBrutto: customerCart.totalBrutto,
            status: 'pending',
            notes: null,
            items: customerCart.items
                .map((item) => OrderItem(
                      productId: item.product.id,
                      productCode: item.product.code,
                      productName: item.product.name,
                      quantity: item.quantity.toDouble(),
                      priceNetto: item.product.priceNetto,
                      vatRate: item.product.vatRate ?? 23,
                      total: item.totalNetto,
                    ))
                .toList(),
          );

          await DatabaseHelper.instance.insertPendingOrder(order);
          try {
            await apiService.createOrder(order.toJson());
          } catch (_) {}

          successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      // Zamówienie dla nowego klienta
      if (state.newCustomerItems.isNotEmpty && state.newCustomerData != null) {
        try {
          final order = Order(
            customerId: null,
            customerName: 'NOWY KLIENT',
            orderDate: DateTime.now(),
            totalNetto: state.newCustomerItems.fold<double>(0.0, (double sum, item) => sum + item.totalNetto),
            totalBrutto: state.newCustomerItems.fold<double>(0.0, (double sum, item) => sum + item.totalBrutto),
            status: 'pending',
            notes: '[NOWY KLIENT]\n${state.newCustomerData}',
            items: state.newCustomerItems
                .map((item) => OrderItem(
                      productId: item.product.id,
                      productCode: item.product.code,
                      productName: item.product.name,
                      quantity: item.quantity.toDouble(),
                      priceNetto: item.product.priceNetto,
                      vatRate: item.product.vatRate ?? 23,
                      total: item.totalNetto,
                    ))
                .toList(),
          );

          await DatabaseHelper.instance.insertPendingOrder(order);
          try {
            await apiService.createOrder(order.toJson());
          } catch (_) {}

          successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      // Wyczyść koszyk
      cartCubit.clearCart();

      // Zamknij dialog ładowania
      if (context.mounted) {
        Navigator.of(context).pop();

        if (errorCount == 0) {
          AppNotification.success(
            context,
            successCount > 1
                ? 'Utworzono $successCount zamówień!'
                : 'Zamówienie utworzone!',
          );
        } else {
          AppNotification.error(
            context,
            'Utworzono $successCount, błędów: $errorCount',
          );
        }

        // Wróć do dashboard
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        AppNotification.error(context, 'Błąd tworzenia zamówień');
      }
    }
  }
}
