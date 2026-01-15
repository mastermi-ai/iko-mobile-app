import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/cart_cubit.dart';
import '../models/saved_cart.dart';
import '../models/customer.dart';
import '../database/database_helper.dart';

class SavedCartsScreen extends StatefulWidget {
  const SavedCartsScreen({super.key});

  @override
  State<SavedCartsScreen> createState() => _SavedCartsScreenState();
}

class _SavedCartsScreenState extends State<SavedCartsScreen> {
  List<SavedCart> _savedCarts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSavedCarts();
  }

  Future<void> _loadSavedCarts() async {
    setState(() => _isLoading = true);
    try {
      final carts = _searchQuery.isEmpty
          ? await DatabaseHelper.instance.getSavedCarts()
          : await DatabaseHelper.instance.searchSavedCarts(_searchQuery);
      setState(() {
        _savedCarts = carts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd ładowania schowków: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schowki'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _saveCurrentCart(context),
            tooltip: 'Zapisz aktualny koszyk',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Szukaj schowka...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadSavedCarts();
              },
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _savedCarts.isEmpty
                    ? _buildEmptyState()
                    : _buildCartsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _saveCurrentCart(context),
        icon: const Icon(Icons.save),
        label: const Text('Zapisz koszyk'),
        backgroundColor: Colors.teal[700],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Brak zapisanych schowków',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Zapisz aktualny koszyk aby móc go\nwczytać później',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCartsList() {
    return RefreshIndicator(
      onRefresh: _loadSavedCarts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _savedCarts.length,
        itemBuilder: (context, index) {
          final cart = _savedCarts[index];
          return _SavedCartCard(
            cart: cart,
            onLoad: () => _loadCart(cart),
            onDelete: () => _deleteCart(cart),
            onRename: () => _renameCart(cart),
          );
        },
      ),
    );
  }

  Future<void> _saveCurrentCart(BuildContext context) async {
    final cartCubit = context.read<CartCubit>();
    final cartState = cartCubit.getCurrentCart();

    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koszyk jest pusty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show name dialog
    final name = await _showNameDialog(context, 'Zapisz schowek');
    if (name == null || name.isEmpty) return;

    try {
      final savedCart = SavedCart.fromCartState(
        name: name,
        items: cartState.items,
        customer: cartState.selectedCustomer,
        totalNetto: cartState.totalNetto,
        totalBrutto: cartState.totalBrutto,
      );

      await DatabaseHelper.instance.saveCart(savedCart);
      await _loadSavedCarts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schowek "$name" został zapisany'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd zapisywania: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCart(SavedCart cart) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wczytaj schowek'),
        content: Text(
          'Czy chcesz wczytać schowek "${cart.name}"?\n\n'
          'Aktualny koszyk zostanie zastąpiony.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Wczytaj'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final cartCubit = context.read<CartCubit>();
      final products = await DatabaseHelper.instance.getProducts();

      // Clear current cart
      cartCubit.clearCart();

      // Load customer if exists
      if (cart.customerId != null) {
        final customers = await DatabaseHelper.instance.getCustomers();
        final customer = customers.where((c) => c.id == cart.customerId).firstOrNull;
        if (customer != null) {
          cartCubit.selectCustomer(customer);
        }
      }

      // Add items to cart
      for (final item in cart.items) {
        // Try to find product in local DB first
        final product = products.where((p) => p.id == item.productId).firstOrNull;
        if (product != null) {
          cartCubit.addProduct(product, quantity: item.quantity);
        } else {
          // Use saved product data as fallback
          cartCubit.addProduct(item.toProduct(), quantity: item.quantity);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schowek "${cart.name}" został wczytany'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Go back to cart
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd wczytywania: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCart(SavedCart cart) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń schowek'),
        content: Text('Czy na pewno chcesz usunąć schowek "${cart.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Usuń',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || cart.id == null) return;

    try {
      await DatabaseHelper.instance.deleteSavedCart(cart.id!);
      await _loadSavedCarts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schowek "${cart.name}" został usunięty'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd usuwania: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _renameCart(SavedCart cart) async {
    final newName = await _showNameDialog(
      context,
      'Zmień nazwę',
      initialValue: cart.name,
    );
    if (newName == null || newName.isEmpty || cart.id == null) return;

    try {
      await DatabaseHelper.instance.renameSavedCart(cart.id!, newName);
      await _loadSavedCarts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nazwa została zmieniona'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd zmiany nazwy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showNameDialog(
    BuildContext context,
    String title, {
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nazwa schowka',
            hintText: 'np. Klient ABC - zamówienie tygodniowe',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }
}

class _SavedCartCard extends StatelessWidget {
  final SavedCart cart;
  final VoidCallback onLoad;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _SavedCartCard({
    required this.cart,
    required this.onLoad,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onLoad,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.folder,
                      color: Colors.teal[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cart.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (cart.customerName != null)
                          Text(
                            cart.customerName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') onRename();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Zmień nazwę'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Usuń', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Details
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.inventory_2,
                    label: '${cart.itemCount} szt',
                  ),
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.list,
                    label: '${cart.items.length} pozycji',
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${cart.totalNetto.toStringAsFixed(2)} zł',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[700],
                        ),
                      ),
                      if (cart.totalBrutto != null)
                        Text(
                          '${cart.totalBrutto!.toStringAsFixed(2)} zł brutto',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Date
              Text(
                'Zapisano: ${dateFormat.format(cart.updatedAt ?? cart.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
