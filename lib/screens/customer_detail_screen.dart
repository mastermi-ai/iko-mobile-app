import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../models/cart_item.dart';
import '../../bloc/cart_cubit.dart';
import '../../services/api_service.dart';
import '../../widgets/app_notification.dart';
import '../../database/database_helper.dart';
import 'products_list_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<_OrderGroup> _orderGroups = [];
  bool _loadingHistory = false;
  String? _historyError;
  final Set<int> _expandedOrders = {};

  @override
  void initState() {
    super.initState();
    _loadAllOrders();
  }

  Future<void> _loadAllOrders() async {
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });

    try {
      final apiService = ApiService();
      final allOrders = <_OrderData>[];

      // 1. Pobierz zamówienia z naszej aplikacji (ZK)
      try {
        final appOrders = await apiService.getCustomerOrders(widget.customer.id);
        for (final order in appOrders) {
          allOrders.add(_OrderData(
            id: order['id'] as int,
            documentNumber: order['orderNumber'] ?? order['nexoDocId'] ?? 'ZK #${order['id']}',
            documentType: 'ZK',
            documentDate: DateTime.parse(order['orderDate'] ?? order['createdAt']),
            totalNetto: (order['totalNetto'] as num?)?.toDouble() ?? 0,
            totalBrutto: (order['totalBrutto'] as num?)?.toDouble() ?? 0,
            status: order['status'] ?? 'completed',
            items: (order['items'] as List<dynamic>?)?.map((item) => _OrderItemData(
              productCode: item['productCode'] ?? '',
              productName: item['productName'] ?? '',
              quantity: (item['quantity'] as num?)?.toDouble() ?? 1,
              priceNetto: (item['priceNetto'] as num?)?.toDouble() ?? 0,
            )).toList() ?? [],
            isFromApp: true,
          ));
        }
      } catch (e) {
        // Ignore errors from app orders - may not have endpoint yet
      }

      // 2. Pobierz historię z nexo PRO (FS, PA, WZ)
      try {
        final nexoHistory = await apiService.getCustomerOrderHistory(widget.customer.id);
        for (final doc in nexoHistory) {
          allOrders.add(_OrderData(
            id: doc['id'] as int? ?? 0,
            documentNumber: doc['documentNumber'] ?? '',
            documentType: doc['documentType'] ?? '',
            documentDate: DateTime.parse(doc['documentDate'] ?? DateTime.now().toIso8601String()),
            totalNetto: (doc['totalNetto'] as num?)?.toDouble() ?? 0,
            totalBrutto: (doc['totalBrutto'] as num?)?.toDouble() ?? 0,
            status: 'completed',
            items: [],
            isFromApp: false,
          ));
        }
      } catch (e) {
        // Ignore errors from nexo history
      }

      // Sortuj po dacie (najnowsze pierwsze)
      allOrders.sort((a, b) => b.documentDate.compareTo(a.documentDate));

      // Grupuj po dacie
      final groups = <String, List<_OrderData>>{};
      for (final order in allOrders) {
        final dateKey = DateFormat('yyyy-MM-dd').format(order.documentDate);
        groups.putIfAbsent(dateKey, () => []);
        groups[dateKey]!.add(order);
      }

      // Konwertuj na listę grup
      final orderGroups = groups.entries.map((entry) {
        return _OrderGroup(
          date: DateTime.parse(entry.key),
          orders: entry.value,
        );
      }).toList();

      // Sortuj grupy po dacie (najnowsze pierwsze)
      orderGroups.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _orderGroups = orderGroups;
          _loadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = 'Nie udało się pobrać historii: $e';
          _loadingHistory = false;
        });
      }
    }
  }

  void _startNewOrder(BuildContext context) {
    final cartCubit = context.read<CartCubit>();
    cartCubit.selectCustomer(widget.customer);

    AppNotification.success(
      context,
      'Klient aktywny: ${widget.customer.shortName ?? widget.customer.name}',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductsListScreen(),
      ),
    );
  }

  Future<void> _repeatOrder(_OrderData order) async {
    if (order.items.isEmpty) {
      if (mounted) {
        AppNotification.error(context, 'Brak pozycji do powtórzenia');
      }
      return;
    }

    final cartCubit = context.read<CartCubit>();
    final dbHelper = DatabaseHelper.instance;
    
    // Wybierz klienta
    cartCubit.selectCustomer(widget.customer);

    int addedCount = 0;
    
    for (final item in order.items) {
      // Znajdź produkt w bazie po kodzie
      final products = await dbHelper.searchProducts(item.productCode);
      if (products.isNotEmpty) {
        final product = products.first;
        cartCubit.addItem(CartItem(
          product: product,
          quantity: item.quantity.toInt(),
        ));
        addedCount++;
      }
    }

    if (mounted) {
      if (addedCount > 0) {
        AppNotification.success(
          context, 
          'Dodano $addedCount produktów do koszyka',
        );
      } else {
        AppNotification.error(context, 'Nie znaleziono produktów');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły klienta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllOrders,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Header
            _buildCustomerHeader(),

            // Contact Information
            _buildSection(
              title: 'Kontakt',
              icon: Icons.contact_phone,
              children: [
                if (widget.customer.address != null)
                  _buildInfoRow(Icons.home, 'Adres', widget.customer.address!),
                if (widget.customer.postalCode != null || widget.customer.city != null)
                  _buildInfoRow(
                    Icons.location_city,
                    'Kod/Miasto',
                    '${widget.customer.postalCode ?? ''} ${widget.customer.city ?? ''}'.trim(),
                  ),
                if (widget.customer.phone1 != null)
                  _buildInfoRow(Icons.phone, 'Telefon', widget.customer.phone1!),
                if (widget.customer.email != null)
                  _buildInfoRow(Icons.email, 'Email', widget.customer.email!),
              ],
            ),

            // Company Information
            if (widget.customer.nip != null)
              _buildSection(
                title: 'Dane firmowe',
                icon: Icons.business,
                children: [
                  _buildInfoRow(Icons.receipt_long, 'NIP', widget.customer.nip!),
                ],
              ),

            const SizedBox(height: 16),

            // Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () => _startNewOrder(context),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Nowe zamówienie', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Order History Section
            _buildOrderHistorySection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: Colors.green[50],
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, size: 40, color: Colors.green[700]),
          ),
          const SizedBox(height: 12),
          Text(
            widget.customer.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (widget.customer.shortName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.customer.shortName!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Icon(Icons.history, size: 20, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'Historia zamówień',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),
        
        if (_loadingHistory)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_historyError != null)
          _buildErrorWidget()
        else if (_orderGroups.isEmpty)
          _buildEmptyWidget()
        else
          ..._orderGroups.map((group) => _buildDateGroup(group)),
      ],
    );
  }

  Widget _buildDateGroup(_OrderGroup group) {
    final dateFormat = DateFormat('d MMMM yyyy', 'pl_PL');
    final isToday = DateUtils.isSameDay(group.date, DateTime.now());
    final isYesterday = DateUtils.isSameDay(
      group.date, 
      DateTime.now().subtract(const Duration(days: 1)),
    );

    String dateLabel;
    if (isToday) {
      dateLabel = 'Dzisiaj';
    } else if (isYesterday) {
      dateLabel = 'Wczoraj';
    } else {
      dateLabel = dateFormat.format(group.date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[200],
          child: Text(
            dateLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        ...group.orders.map((order) => _buildOrderCard(order)),
      ],
    );
  }

  Widget _buildOrderCard(_OrderData order) {
    final isExpanded = _expandedOrders.contains(order.id);
    final hasItems = order.items.isNotEmpty;
    
    Color typeColor;
    String typeLabel;
    
    switch (order.documentType) {
      case 'ZK':
        typeColor = Colors.blue;
        typeLabel = 'Zamówienie';
        break;
      case 'FS':
        typeColor = Colors.green;
        typeLabel = 'Faktura';
        break;
      case 'PA':
        typeColor = Colors.orange;
        typeLabel = 'Paragon';
        break;
      case 'WZ':
        typeColor = Colors.purple;
        typeLabel = 'Wydanie';
        break;
      case 'FP':
        typeColor = Colors.teal;
        typeLabel = 'Pro forma';
        break;
      default:
        typeColor = Colors.grey;
        typeLabel = order.documentType;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          InkWell(
            onTap: hasItems ? () {
              setState(() {
                if (isExpanded) {
                  _expandedOrders.remove(order.id);
                } else {
                  _expandedOrders.add(order.id);
                }
              });
            } : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Document info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.documentNumber,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          DateFormat('HH:mm').format(order.documentDate),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  // Total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${order.totalBrutto.toStringAsFixed(2)} zł',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                      ),
                      if (order.isFromApp && order.status != 'completed')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: order.status == 'pending' ? Colors.orange : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.status == 'pending' ? 'Oczekuje' : 'Błąd',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  if (hasItems)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Expanded items
          if (isExpanded && hasItems) ...[
            const Divider(height: 1),
            Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Items list
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${item.quantity.toInt()}x',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item.productCode,
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(item.priceNetto * item.quantity).toStringAsFixed(2)} zł',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  )),
                  
                  const SizedBox(height: 12),
                  
                  // Repeat order button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _repeatOrder(order),
                      icon: const Icon(Icons.replay, size: 18),
                      label: const Text('Powtórz zamówienie'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 48),
            const SizedBox(height: 8),
            Text(_historyError!, style: TextStyle(color: Colors.red[300])),
            TextButton(
              onPressed: _loadAllOrders,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox, color: Colors.grey[400], size: 48),
            const SizedBox(height: 8),
            Text(
              'Brak historii zamówień',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// Data classes
class _OrderGroup {
  final DateTime date;
  final List<_OrderData> orders;

  _OrderGroup({required this.date, required this.orders});
}

class _OrderData {
  final int id;
  final String documentNumber;
  final String documentType;
  final DateTime documentDate;
  final double totalNetto;
  final double totalBrutto;
  final String status;
  final List<_OrderItemData> items;
  final bool isFromApp;

  _OrderData({
    required this.id,
    required this.documentNumber,
    required this.documentType,
    required this.documentDate,
    required this.totalNetto,
    required this.totalBrutto,
    required this.status,
    required this.items,
    required this.isFromApp,
  });
}

class _OrderItemData {
  final String productCode;
  final String productName;
  final double quantity;
  final double priceNetto;

  _OrderItemData({
    required this.productCode,
    required this.productName,
    required this.quantity,
    required this.priceNetto,
  });
}
