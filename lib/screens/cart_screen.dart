import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cart_cubit.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/quote.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';
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

          // Action buttons row
          Row(
            children: [
              // Create Quote button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.canCheckout
                      ? () => _createQuote(context)
                      : null,
                  icon: const Icon(Icons.local_offer),
                  label: const Text(
                    'Utwórz ofertę',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Create Order button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.canCheckout
                      ? () => _createOrder(context)
                      : null,
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'Utwórz zamówienie',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),

          // Info text when customer not selected
          if (state.selectedCustomer == null && state.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Wybierz klienta aby kontynuować',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _createQuote(BuildContext context) async {
    final cartCubit = context.read<CartCubit>();
    final cart = cartCubit.getCurrentCart();

    // Show validity period dialog
    final validDays = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ważność oferty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Wybierz okres ważności oferty:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ValidityChip(days: 7, onTap: () => Navigator.of(dialogContext).pop(7)),
                _ValidityChip(days: 14, onTap: () => Navigator.of(dialogContext).pop(14)),
                _ValidityChip(days: 30, onTap: () => Navigator.of(dialogContext).pop(30)),
                _ValidityChip(days: 60, onTap: () => Navigator.of(dialogContext).pop(60)),
                _ValidityChip(days: 90, onTap: () => Navigator.of(dialogContext).pop(90)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(0), // 0 = no expiry
            child: const Text('Bez terminu'),
          ),
        ],
      ),
    );

    if (validDays == null || !context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Calculate validity date
      DateTime? validUntil;
      if (validDays > 0) {
        validUntil = DateTime.now().add(Duration(days: validDays));
      }

      // Create quote object
      final quote = Quote(
        customerId: cart.selectedCustomer!.id,
        customerName: cart.selectedCustomer!.name,
        quoteDate: DateTime.now(),
        validUntil: validUntil,
        status: 'draft',
        totalNetto: cart.totalNetto,
        totalBrutto: cart.totalBrutto,
        items: cart.items
            .map((item) => QuoteItem(
                  productId: item.product.id!,
                  productCode: item.product.code,
                  productName: item.product.name,
                  quantity: item.quantity.toDouble(),
                  priceNetto: item.product.priceNetto,
                  priceBrutto: item.product.priceBrutto,
                  vatRate: item.product.vatRate ?? 23,
                  total: item.totalNetto,
                ))
            .toList(),
      );

      // Save to local database
      await DatabaseHelper.instance.insertQuote(quote);

      // Try to sync with Cloud API
      try {
        await ApiService().createQuote(quote.toJson());
      } catch (e) {
        // API sync failed - quote will be synced later
      }

      // Clear cart
      cartCubit.clearCart();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              validUntil != null
                  ? 'Oferta utworzona! Ważna do ${validUntil.day}.${validUntil.month}.${validUntil.year}'
                  : 'Oferta utworzona pomyślnie!',
            ),
            backgroundColor: Colors.orange[700],
            duration: const Duration(seconds: 3),
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
            content: Text('Błąd tworzenia oferty: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        await ApiService().createOrder(order.toJson());
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

class _ValidityChip extends StatelessWidget {
  final int days;
  final VoidCallback onTap;

  const _ValidityChip({
    required this.days,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text('$days dni'),
      onPressed: onTap,
      backgroundColor: Colors.orange[100],
      labelStyle: TextStyle(
        color: Colors.orange[800],
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
