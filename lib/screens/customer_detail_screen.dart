import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/customer.dart';
import '../../bloc/cart_cubit.dart';
import '../../services/api_service.dart';
import '../../widgets/app_notification.dart';
import 'products_list_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<Map<String, dynamic>>? _orderHistory;
  bool _loadingHistory = false;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _loadOrderHistory();
  }

  Future<void> _loadOrderHistory() async {
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });

    try {
      final apiService = ApiService();
      await apiService.loadToken();
      // Use nexoId for fetching order history from nexo PRO
      final nexoId = widget.customer.nexoId ?? widget.customer.id.toString();
      final history = await apiService.getCustomerOrderHistory(int.tryParse(nexoId) ?? widget.customer.id);
      if (mounted) {
        setState(() {
          _orderHistory = history;
          _loadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = 'Nie udało się pobrać historii';
          _loadingHistory = false;
        });
      }
    }
  }

  void _startNewOrder(BuildContext context) {
    final cartCubit = context.read<CartCubit>();

    // Multi-koszyk: po prostu wybierz klienta jako aktywnego
    // Produkty poprzednich klientów zostają w ich koszykach
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły klienta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderHistory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.green[50],
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.customer.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.customer.shortName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.customer.shortName!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Contact Information
            _buildSection(
              context,
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
                if (widget.customer.voivodeship != null)
                  _buildInfoRow(Icons.map, 'Województwo', widget.customer.voivodeship!),
                if (widget.customer.phone1 != null)
                  _buildInfoRow(Icons.phone, 'Telefon 1', widget.customer.phone1!),
                if (widget.customer.phone2 != null)
                  _buildInfoRow(Icons.phone, 'Telefon 2', widget.customer.phone2!),
                if (widget.customer.email != null)
                  _buildInfoRow(Icons.email, 'Email', widget.customer.email!),
              ],
            ),

            // Company Information
            if (widget.customer.nip != null || widget.customer.regon != null)
              _buildSection(
                context,
                title: 'Dane firmowe',
                icon: Icons.business,
                children: [
                  if (widget.customer.nip != null)
                    _buildInfoRow(Icons.receipt_long, 'NIP', widget.customer.nip!),
                  if (widget.customer.regon != null)
                    _buildInfoRow(Icons.badge, 'REGON', widget.customer.regon!),
                ],
              ),

            const SizedBox(height: 16),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _startNewOrder(context),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text(
                      'Nowe zamówienie',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Order History Section
            _buildSection(
              context,
              title: 'Historia zamówień',
              icon: Icons.history,
              children: [
                if (_loadingHistory)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_historyError != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[300], size: 48),
                          const SizedBox(height: 8),
                          Text(_historyError!, style: TextStyle(color: Colors.red[300])),
                          TextButton(
                            onPressed: _loadOrderHistory,
                            child: const Text('Spróbuj ponownie'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_orderHistory == null || _orderHistory!.isEmpty)
                  Padding(
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
                  )
                else
                  ..._orderHistory!.map((order) => _buildOrderHistoryItem(order)),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistoryItem(Map<String, dynamic> order) {
    final docNumber = order['documentNumber'] ?? 'Brak numeru';
    final docType = order['documentType'] ?? '';
    final docDate = order['documentDate']?.toString().substring(0, 10) ?? '';
    final totalBrutto = (order['totalBrutto'] as num?)?.toDouble() ?? 0;

    String docTypeLabel = docType;
    Color docTypeColor = Colors.blue;
    switch (docType) {
      case 'FS':
        docTypeLabel = 'Faktura';
        docTypeColor = Colors.blue;
        break;
      case 'PA':
        docTypeLabel = 'Paragon';
        docTypeColor = Colors.green;
        break;
      case 'WZ':
        docTypeLabel = 'Wydanie';
        docTypeColor = Colors.orange;
        break;
      case 'FP':
        docTypeLabel = 'Faktura pro forma';
        docTypeColor = Colors.purple;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: docTypeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            docTypeLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: docTypeColor,
            ),
          ),
        ),
        title: Text(
          docNumber,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(docDate),
        trailing: Text(
          '${totalBrutto.toStringAsFixed(2)} zł',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.green[700],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
