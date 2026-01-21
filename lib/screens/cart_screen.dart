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
              // Customer selection (istniejący lub nowy)
              _CustomerSelector(state: state),

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

/// Wybór klienta - istniejący z bazy LUB nowy (dane w uwagach)
/// 
/// LOGIKA (wymaganie klienta):
/// - Handlowiec może wybrać klienta z bazy nexo
/// - LUB zaznaczyć "Nowy klient" i wpisać NIP + dane
/// - Dane nowego klienta trafiają do UWAG zamówienia
/// - Biuro tworzy kartę kontrahenta w nexo przed przetworzeniem
class _CustomerSelector extends StatelessWidget {
  final CartState state;

  const _CustomerSelector({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasCustomer = state.selectedCustomer != null || state.isNewCustomer;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: hasCustomer ? Colors.green[50] : Colors.orange[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasCustomer ? Icons.check_circle : Icons.warning_amber,
                color: hasCustomer ? Colors.green[700] : Colors.orange[700],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.customerDisplayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasCustomer ? Colors.green[900] : Colors.orange[900],
                      ),
                    ),
                    if (state.selectedCustomer != null && state.selectedCustomer!.city != null)
                      Text(
                        state.selectedCustomer!.city!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    // Wyświetl saldo klienta (rozrachunki)
                    if (state.selectedCustomer != null && state.selectedCustomer!.balance != null)
                      Text(
                        'Saldo: ${state.selectedCustomer!.formattedBalance}',
                        style: TextStyle(
                          fontSize: 13,
                          color: state.selectedCustomer!.hasDebt ? Colors.red[700] : Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              // Przycisk wyboru istniejącego klienta
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CustomersListScreen(),
                    ),
                  );
                },
                icon: Icon(state.selectedCustomer == null ? Icons.person_search : Icons.edit),
                label: Text(state.selectedCustomer == null ? 'Z bazy' : 'Zmień'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              // Przycisk "Nowy klient"
              ElevatedButton.icon(
                onPressed: () => _showNewCustomerDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Nowy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.isNewCustomer ? Colors.green[700] : Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          // Wyświetl dane nowego klienta jeśli wprowadzone
          if (state.isNewCustomer && state.newCustomerData != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Dane nowego klienta (trafią do uwag ZK):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.newCustomerData!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showNewCustomerDialog(BuildContext context) {
    final nipController = TextEditingController();
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    
    // Jeśli już są dane nowego klienta, spróbuj je wczytać
    if (state.newCustomerData != null) {
      final lines = state.newCustomerData!.split('\n');
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
            Text('Nowy klient'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wpisz dane klienta - trafią do uwag zamówienia.\n'
                'Biuro utworzy kartę kontrahenta w nexo.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nipController,
                decoration: const InputDecoration(
                  labelText: 'NIP *',
                  hintText: '1234567890',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa firmy *',
                  hintText: 'Firma XYZ Sp. z o.o.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Adres',
                  hintText: 'ul. Przykładowa 1, 00-001 Warszawa',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Anuluj i wyczyść dane nowego klienta
              context.read<CartCubit>().clearNewCustomer();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              final nip = nipController.text.trim();
              final name = nameController.text.trim();
              final address = addressController.text.trim();
              
              if (nip.isEmpty || name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('NIP i Nazwa firmy są wymagane!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Zbuduj dane nowego klienta
              final customerData = [
                'NIP: $nip',
                'Nazwa: $name',
                if (address.isNotEmpty) 'Adres: $address',
              ].join('\n');
              
              context.read<CartCubit>().setNewCustomer(customerData);
              Navigator.of(dialogContext).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dane nowego klienta zapisane'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Zapisz'),
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
          if (!state.canCheckout && state.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Wybierz klienta z bazy lub wpisz dane nowego klienta',
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
      // Przygotuj dane klienta
      // Jeśli nowy klient: customerId = null, dane w notes
      // Jeśli istniejący: customerId z bazy
      final int? customerId = cart.isNewCustomer ? null : cart.selectedCustomer?.id;
      final String? customerName = cart.isNewCustomer 
          ? 'NOWY KLIENT' 
          : cart.selectedCustomer?.name;
      
      // Uwagi: dane nowego klienta + ewentualne dodatkowe uwagi
      final String? notes = cart.fullOrderNotes;
      
      // Create order object
      // CENY PÓŁKOWE - finalna kalkulacja rabatów w nexo PRO
      final order = Order(
        customerId: customerId,
        customerName: customerName,
        orderDate: DateTime.now(),
        totalNetto: cart.totalNetto,  // Suma cen półkowych
        totalBrutto: cart.totalBrutto,
        status: 'pending',
        notes: notes,  // Zawiera dane nowego klienta jeśli applicable
        items: cart.items
            .map((item) {
              final itemTotal = item.totalNetto;
              return OrderItem(
                  productId: item.product.id,
                  productCode: item.product.code,
                  productName: item.product.name,
                  quantity: item.quantity.toDouble(),
                  priceNetto: item.product.priceNetto,  // Cena półkowa
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
        // Order saved locally, will sync when online
      }

      // Clear cart
      cartCubit.clearCart();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show success message
        final message = cart.isNewCustomer 
            ? 'Zamówienie utworzone dla NOWEGO KLIENTA!\nDane w uwagach - biuro utworzy kartę.'
            : 'Zamówienie utworzone pomyślnie!';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
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
