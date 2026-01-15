import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/cart_cubit.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../database/database_helper.dart';
import '../../services/api_service.dart';
import 'customers_list_screen.dart';

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
            onPressed: () {
              _showClearCartDialog(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
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
                    'Dodaj produkty aby utworzyć zamówienie',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Przeglądaj produkty'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Customer selection
              _CustomerSelector(customer: state.selectedCustomer),

              // Cart items list
              Expanded(
                child: ListView.builder(
                  itemCount: state.items.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    return _CartItemCard(item: state.items[index]);
                  },
                ),
              ),

              // Cart summary
              _CartSummary(state: state),
            ],
          );
        },
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wyczyść koszyk'),
        content: const Text('Czy na pewno chcesz usunąć wszystkie produkty z koszyka?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              context.read<CartCubit>().clearCart();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Wyczyść',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerSelector extends StatelessWidget {
  final dynamic customer;

  const _CustomerSelector({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: customer == null ? Colors.orange[50] : Colors.green[50],
      child: Row(
        children: [
          Icon(
            customer == null ? Icons.warning_amber : Icons.check_circle,
            color: customer == null ? Colors.orange[700] : Colors.green[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer == null ? 'Wybierz klienta' : customer.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: customer == null ? Colors.orange[900] : Colors.green[900],
                  ),
                ),
                if (customer != null && customer.city != null)
                  Text(
                    customer.city!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CustomersListScreen(),
                ),
              );
            },
            icon: Icon(customer == null ? Icons.add : Icons.edit),
            label: Text(customer == null ? 'Wybierz' : 'Zmień'),
            style: ElevatedButton.styleFrom(
              backgroundColor: customer == null ? Colors.orange[700] : Colors.green[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;

  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2, size: 30, color: Colors.grey),
            ),
            const SizedBox(width: 12),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.product.priceNetto.toStringAsFixed(2)} zł/szt',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Razem: ${item.totalNetto.toStringAsFixed(2)} zł',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity controls
            Column(
              children: [
                _QuantityControl(item: item),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    context.read<CartCubit>().removeProduct(item.product);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final CartItem item;

  const _QuantityControl({required this.item});

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
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () {
              context.read<CartCubit>().updateQuantity(
                    item.product,
                    item.quantity - 1,
                  );
            },
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () {
              context.read<CartCubit>().updateQuantity(
                    item.product,
                    item.quantity + 1,
                  );
            },
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Produkty:',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '${state.itemCount} szt',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Wartość netto:',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '${state.totalNetto.toStringAsFixed(2)} zł',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Wartość brutto:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${state.totalBrutto.toStringAsFixed(2)} zł',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.canCheckout
                  ? () => _createOrder(context)
                  : null,
              icon: const Icon(Icons.check_circle),
              label: Text(
                state.selectedCustomer == null
                    ? 'Wybierz klienta aby kontynuować'
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
    );
  }

  Future<void> _createOrder(BuildContext context) async {
    final cartCubit = context.read<CartCubit>();
    final cart = cartCubit.getCurrentCart();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Create order object
      final order = Order(
        customerId: cart.selectedCustomer!.id!,
        orderDate: DateTime.now(),
        totalNetto: cart.totalNetto,
        totalBrutto: cart.totalBrutto,
        status: 'pending',
        items: cart.items
            .map((item) {
              final itemTotal = item.totalNetto;
              return OrderItem(
                  productId: item.product.id!,
                  productCode: item.product.code,
                  productName: item.product.name,
                  quantity: item.quantity.toDouble(),
                  priceNetto: item.product.priceNetto,
                  vatRate: item.product.vatRate ?? 23,
                  total: itemTotal,
                );
            })
            .toList(),
      );

      // Save to local database (pending_orders)
      await DatabaseHelper.instance.insertPendingOrder(order);

      // Try to sync with Cloud API
      try {
        await ApiService().createOrder(order);
      } catch (e) {
        // API sync failed - order will be synced later in background
        // ignore: avoid_print
        // Order saved locally, will sync when online
      }

      // Clear cart
      cartCubit.clearCart();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zamówienie utworzone pomyślnie!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Go back to dashboard
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd tworzenia zamówienia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
