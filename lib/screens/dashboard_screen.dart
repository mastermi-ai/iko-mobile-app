import 'package:flutter/material.dart';
import '../models/user.dart';
import 'products_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  final User user;

  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IKO - Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              // TODO: Implement sync
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Synchronizacja...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Implement logout
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Witaj, ${user.name}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.clientName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildModuleTile(
                    context,
                    icon: Icons.shopping_bag,
                    title: 'Produkty',
                    subtitle: 'Katalog',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProductsListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildModuleTile(
                    context,
                    icon: Icons.people,
                    title: 'Klienci',
                    subtitle: 'Lista',
                    color: Colors.green,
                    onTap: () {
                      // TODO: Navigate to customers
                    },
                  ),
                  _buildModuleTile(
                    context,
                    icon: Icons.receipt_long,
                    title: 'Zamówienia',
                    subtitle: 'Historia',
                    color: Colors.orange,
                    onTap: () {
                      // TODO: Navigate to orders
                    },
                  ),
                  _buildModuleTile(
                    context,
                    icon: Icons.shopping_cart,
                    title: 'Koszyk',
                    subtitle: 'Nowe zamówienie',
                    color: Colors.purple,
                    onTap: () {
                      // TODO: Navigate to cart
                    },
                  ),
                  _buildModuleTile(
                    context,
                    icon: Icons.local_offer,
                    title: 'Oferty',
                    subtitle: 'Promocje',
                    color: Colors.red,
                    onTap: () {
                      // TODO: Navigate to offers
                    },
                  ),
                  _buildModuleTile(
                    context,
                    icon: Icons.description,
                    title: 'Faktury',
                    subtitle: 'Dokumenty',
                    color: Colors.teal,
                    onTap: () {
                      // TODO: Navigate to invoices
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
