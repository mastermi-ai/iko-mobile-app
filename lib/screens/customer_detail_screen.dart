import 'package:flutter/material.dart';
import '../../models/customer.dart';

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły klienta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Edit customer
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edycja - wkrótce')),
              );
            },
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
                    customer.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (customer.shortName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      customer.shortName!,
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
                if (customer.address != null)
                  _buildInfoRow(Icons.home, 'Adres', customer.address!),
                if (customer.postalCode != null || customer.city != null)
                  _buildInfoRow(
                    Icons.location_city,
                    'Kod/Miasto',
                    '${customer.postalCode ?? ''} ${customer.city ?? ''}'.trim(),
                  ),
                if (customer.voivodeship != null)
                  _buildInfoRow(Icons.map, 'Województwo', customer.voivodeship!),
                if (customer.phone1 != null)
                  _buildInfoRow(Icons.phone, 'Telefon 1', customer.phone1!),
                if (customer.phone2 != null)
                  _buildInfoRow(Icons.phone, 'Telefon 2', customer.phone2!),
                if (customer.email != null)
                  _buildInfoRow(Icons.email, 'Email', customer.email!),
              ],
            ),

            // Company Information
            if (customer.nip != null || customer.regon != null)
              _buildSection(
                context,
                title: 'Dane firmowe',
                icon: Icons.business,
                children: [
                  if (customer.nip != null)
                    _buildInfoRow(Icons.receipt_long, 'NIP', customer.nip!),
                  if (customer.regon != null)
                    _buildInfoRow(Icons.badge, 'REGON', customer.regon!),
                ],
              ),

            const SizedBox(height: 16),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Create order for this customer
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Nowe zamówienie dla ${customer.name}'),
                          action: SnackBarAction(
                            label: 'KOSZYK',
                            onPressed: () {
                              // TODO: Navigate to cart with selected customer
                            },
                          ),
                        ),
                      );
                    },
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
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: View orders history
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Historia zamówień - wkrótce')),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Historia zamówień'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
