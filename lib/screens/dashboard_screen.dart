import 'package:flutter/material.dart';
import '../models/user.dart';
import 'products_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  final User user;

  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('IKO'),
        backgroundColor: Colors.grey[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Global search
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // User info bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.grey[400],
            child: Row(
              children: [
                const Icon(Icons.person, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user.clientName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.notifications_outlined, size: 20, color: Colors.black54),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // IKO Logo
                    Container(
                      width: 200,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Image.network(
                          'assets/images/iko_logo.jpg',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to text if image fails to load
                            return Container(
                              color: const Color(0xFF1565C0),
                              child: const Center(
                                child: Text(
                                  'IKO',
                                  style: TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Module icons (3x2 grid)
                    Column(
                      children: [
                        // First row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ModuleButton(
                              icon: Icons.inventory_2,
                              label: 'Produkty',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ProductsListScreen(),
                                  ),
                                );
                              },
                            ),
                            _ModuleButton(
                              icon: Icons.people,
                              label: 'Klienci',
                              onTap: () {
                                // TODO: Navigate to customers
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Klienci - wkrótce')),
                                );
                              },
                            ),
                            _ModuleButton(
                              icon: Icons.description,
                              label: 'Zamówienia',
                              onTap: () {
                                // TODO: Navigate to orders
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Zamówienia - wkrótce')),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Second row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ModuleButton(
                              icon: Icons.local_offer,
                              label: 'Oferty',
                              onTap: () {
                                // TODO: Navigate to offers
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Oferty - wkrótce')),
                                );
                              },
                            ),
                            _ModuleButton(
                              icon: Icons.shopping_cart,
                              label: 'Koszyk',
                              onTap: () {
                                // TODO: Navigate to cart
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Koszyk - wkrótce')),
                                );
                              },
                            ),
                            _ModuleButton(
                              icon: Icons.folder,
                              label: 'Schowki',
                              onTap: () {
                                // TODO: Navigate to folders
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Schowki - wkrótce')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Powered by text
                    const Text(
                      'Powered by PRODAUT',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ModuleButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
