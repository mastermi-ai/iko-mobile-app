import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/quotes_bloc.dart';
import '../bloc/cart_cubit.dart';
import '../models/quote.dart';
import '../models/order.dart';
import '../models/customer.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';

class QuoteDetailScreen extends StatelessWidget {
  final Quote quote;
  final bool isLocal;

  const QuoteDetailScreen({
    super.key,
    required this.quote,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuotesBloc(
        databaseHelper: DatabaseHelper.instance,
        apiService: ApiService(),
      ),
      child: _QuoteDetailView(quote: quote, isLocal: isLocal),
    );
  }
}

class _QuoteDetailView extends StatelessWidget {
  final Quote quote;
  final bool isLocal;

  const _QuoteDetailView({
    required this.quote,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return BlocListener<QuotesBloc, QuotesState>(
      listener: (context, state) {
        if (state is QuoteConverted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Oferta została przekonwertowana na zamówienie!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to refresh list
        } else if (state is QuotesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isLocal
                ? 'Oferta #${quote.localId ?? "---"}'
                : 'Oferta #${quote.id}',
          ),
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
          actions: [
            if (isLocal && !quote.synced)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showDeleteDialog(context),
              ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder: (context) => [
                if (quote.status == 'draft' || quote.status == 'sent')
                  const PopupMenuItem(
                    value: 'convert',
                    child: ListTile(
                      leading: Icon(Icons.transform, color: Colors.purple),
                      title: Text('Przekonwertuj na zamówienie'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (quote.status == 'draft')
                  const PopupMenuItem(
                    value: 'send',
                    child: ListTile(
                      leading: Icon(Icons.send, color: Colors.blue),
                      title: Text('Oznacz jako wysłana'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: ListTile(
                    leading: Icon(Icons.copy, color: Colors.grey),
                    title: Text('Duplikuj do koszyka'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner
              _StatusBanner(status: quote.status, isValid: quote.isValid),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer section
                    _SectionCard(
                      title: 'Klient',
                      icon: Icons.person,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quote.customerName ?? 'Klient #${quote.customerId}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (quote.customerId != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${quote.customerId}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Dates section
                    _SectionCard(
                      title: 'Daty',
                      icon: Icons.calendar_today,
                      child: Column(
                        children: [
                          _InfoRow(
                            label: 'Data utworzenia',
                            value: dateFormat.format(quote.quoteDate),
                          ),
                          if (quote.validUntil != null) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Ważna do',
                              value: DateFormat('dd.MM.yyyy').format(quote.validUntil!),
                              valueColor: quote.isValid ? null : Colors.red,
                            ),
                          ],
                          if (quote.createdAt != null) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Zapisano',
                              value: dateFormat.format(quote.createdAt!),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notes section
                    if (quote.notes != null && quote.notes!.isNotEmpty) ...[
                      _SectionCard(
                        title: 'Uwagi',
                        icon: Icons.note,
                        child: Text(
                          quote.notes!,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Items section
                    _SectionCard(
                      title: 'Pozycje (${quote.items.length})',
                      icon: Icons.list_alt,
                      child: Column(
                        children: [
                          ...quote.items.map((item) => _QuoteItemRow(item: item)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Summary section
                    _SummaryCard(quote: quote),

                    const SizedBox(height: 24),

                    // Action buttons
                    if (quote.status == 'draft' || quote.status == 'sent')
                      _ActionButtons(
                        quote: quote,
                        isLocal: isLocal,
                        onConvert: () => _convertToOrder(context),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'convert':
        _convertToOrder(context);
        break;
      case 'send':
        if (isLocal && quote.localId != null) {
          context.read<QuotesBloc>().add(
            UpdateQuoteStatus(localId: quote.localId!, newStatus: 'sent'),
          );
        }
        break;
      case 'duplicate':
        _duplicateToCart(context);
        break;
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usuń ofertę'),
        content: const Text('Czy na pewno chcesz usunąć tę ofertę?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (quote.localId != null) {
                context.read<QuotesBloc>().add(DeleteQuote(quote.localId!));
                Navigator.of(context).pop(true);
              }
            },
            child: const Text(
              'Usuń',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _convertToOrder(BuildContext context) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Przekonwertuj na zamówienie'),
        content: const Text(
          'Czy chcesz utworzyć zamówienie na podstawie tej oferty? '
          'Oferta zostanie oznaczona jako przekonwertowana.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Przekonwertuj'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    // Create order from quote
    final order = Order(
      customerId: quote.customerId,
      orderDate: DateTime.now(),
      totalNetto: quote.totalNetto,
      totalBrutto: quote.totalBrutto,
      status: 'pending',
      notes: 'Utworzone z oferty #${quote.localId ?? quote.id}',
      items: quote.items.map((qi) => OrderItem(
        productId: qi.productId,
        productCode: qi.productCode,
        productName: qi.productName,
        quantity: qi.quantity,
        // quantityExtra USUNIĘTE - gratisy wyłączone przez klienta
        priceNetto: qi.priceNetto,
        priceBrutto: qi.priceBrutto,
        vatRate: qi.vatRate,
        discount: qi.discount,
        notes: qi.notes,
        total: qi.total,
      )).toList(),
    );

    // Save order
    try {
      await DatabaseHelper.instance.insertPendingOrder(order);

      // Mark quote as converted
      if (isLocal && quote.localId != null) {
        context.read<QuotesBloc>().add(
          UpdateQuoteStatus(localId: quote.localId!, newStatus: 'converted'),
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zamówienie zostało utworzone!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _duplicateToCart(BuildContext context) async {
    // Load customer if needed
    Customer? customer;
    if (quote.customerId != null) {
      final customers = await DatabaseHelper.instance.getCustomers();
      customer = customers.where((c) => c.id == quote.customerId).firstOrNull;
    }

    // Load products for cart items
    final products = await DatabaseHelper.instance.getProducts();
    final cartCubit = context.read<CartCubit>();

    // Clear current cart
    cartCubit.clearCart();

    // Set customer if found
    if (customer != null) {
      cartCubit.selectCustomer(customer);
    }

    // Add items to cart
    for (final item in quote.items) {
      final product = products.where((p) => p.id == item.productId).firstOrNull;
      if (product != null) {
        cartCubit.addProduct(product, quantity: item.quantity.toInt());
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pozycje zostały dodane do koszyka'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  final bool isValid;

  const _StatusBanner({
    required this.status,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    switch (status) {
      case 'draft':
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        icon = Icons.edit;
        message = 'Szkic - oferta nie została jeszcze wysłana';
        break;
      case 'sent':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        icon = Icons.send;
        message = 'Oferta została wysłana do klienta';
        break;
      case 'accepted':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        message = 'Oferta została zaakceptowana przez klienta';
        break;
      case 'rejected':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        icon = Icons.cancel;
        message = 'Oferta została odrzucona przez klienta';
        break;
      case 'expired':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        icon = Icons.timer_off;
        message = 'Oferta wygasła';
        break;
      case 'converted':
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[700]!;
        icon = Icons.transform;
        message = 'Oferta została przekonwertowana na zamówienie';
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        icon = Icons.help_outline;
        message = status;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: backgroundColor,
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _QuoteItemRow extends StatelessWidget {
  final QuoteItem item;

  const _QuoteItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kod: ${item.productCode}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Quantity and price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.quantity} x ${item.priceNetto.toStringAsFixed(2)} zł',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.total.toStringAsFixed(2)} zł',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Quote quote;

  const _SummaryCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pozycji:',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '${quote.items.length}',
                  style: const TextStyle(
                    fontSize: 14,
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
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '${quote.totalNetto.toStringAsFixed(2)} zł',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (quote.totalBrutto != null) ...[
              const SizedBox(height: 8),
              const Divider(),
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
                    '${quote.totalBrutto!.toStringAsFixed(2)} zł',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Quote quote;
  final bool isLocal;
  final VoidCallback onConvert;

  const _ActionButtons({
    required this.quote,
    required this.isLocal,
    required this.onConvert,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: onConvert,
          icon: const Icon(Icons.transform),
          label: const Text('Przekonwertuj na zamówienie'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
