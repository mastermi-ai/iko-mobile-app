import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../widgets/app_notification.dart';

class OrderDetailScreen extends StatelessWidget {
  final dynamic order;
  final Map<String, dynamic>? orderData;
  final bool isPending;

  const OrderDetailScreen({
    super.key,
    this.order,
    this.orderData,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    // Extract order info based on source
    final orderDate = isPending
        ? DateTime.parse(orderData!['order_date'] as String)
        : order.orderDate;
    final totalNetto = isPending
        ? (orderData!['total_netto'] as num).toDouble()
        : order.totalNetto;
    final totalBrutto = isPending
        ? (orderData!['total_brutto'] as num?)?.toDouble()
        : order.totalBrutto;

    // Parse items
    List<dynamic> items = [];
    if (isPending && orderData!['items_json'] != null) {
      try {
        items = jsonDecode(orderData!['items_json']);
      } catch (e) {
        items = [];
      }
    } else if (!isPending) {
      items = order.items;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isPending ? 'Zamówienie (oczekujące)' : 'Zamówienie #${order.id}'),
        actions: [
          if (isPending)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () {
                // TODO: Retry sync
                AppNotification.info(context, 'Próba synchronizacji...');
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: isPending ? Colors.orange[50] : Colors.green[50],
              child: Row(
                children: [
                  Icon(
                    isPending ? Icons.pending : Icons.check_circle,
                    color: isPending ? Colors.orange[700] : Colors.green[700],
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPending ? 'Oczekuje na synchronizację' : 'Zsynchronizowane',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isPending ? Colors.orange[900] : Colors.green[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(orderDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Order summary
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Podsumowanie',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Wartość netto:',
                    value: '${totalNetto.toStringAsFixed(2)} zł',
                  ),
                  if (totalBrutto != null)
                    _InfoRow(
                      label: 'Wartość brutto:',
                      value: '${totalBrutto.toStringAsFixed(2)} zł',
                      valueStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Order items
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Pozycje',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${items.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Brak pozycji',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _OrderItemCard(
                        item: item,
                        index: index,
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: valueStyle ??
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final dynamic item;
  final int index;

  const _OrderItemCard({
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // Handle both Map and OrderItem object
    final productName = item is Map
        ? (item['product_name'] ?? 'Produkt')
        : item.productName;
    final productCode = item is Map
        ? (item['product_code'] ?? '')
        : item.productCode;
    final quantity = item is Map
        ? (item['quantity'] as num).toDouble()
        : item.quantity;
    final priceNetto = item is Map
        ? (item['price_netto'] as num).toDouble()
        : item.priceNetto;
    final total = item is Map
        ? (item['total'] as num).toDouble()
        : item.total;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kod: $productCode',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${quantity.toStringAsFixed(0)} × ${priceNetto.toStringAsFixed(2)} zł',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${total.toStringAsFixed(2)} zł',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
