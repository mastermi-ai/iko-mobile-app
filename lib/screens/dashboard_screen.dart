import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/sync_service.dart';
import 'products_list_screen.dart';
import 'customers_list_screen.dart';
import 'cart_screen.dart';
import 'orders_list_screen.dart';
import 'quotes_list_screen.dart';
import 'saved_carts_screen.dart';

class DashboardScreen extends StatefulWidget {
  final User user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isSyncing = false;

  Future<void> _performSync() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      final result = await SyncService.instance.performFullSync();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.success ? 'Synchronizacja zakończona' : 'Błąd synchronizacji',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (result.hasChanges)
                        Text(
                          result.summary,
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(
          'IKO',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Search button (like original) - opens products with search
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProductsListScreen(autoFocusSearch: true),
                ),
              );
            },
            tooltip: 'Szukaj produktów',
          ),
          // Sync button (like original)
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _performSync,
            tooltip: 'Synchronizuj',
          ),
        ],
      ),
      body: Column(
        children: [
          // User info bar (matching original style)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.grey[600],
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.user.clientName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Customers icon (like in original)
                IconButton(
                  icon: const Icon(Icons.people, size: 22, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CustomersListScreen(),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Klienci',
                ),
              ],
            ),
          ),

          // Main content with gradient background like original
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[400]!,
                    Colors.grey[350]!,
                    Colors.grey[300]!,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Top section with logo - large like original app
                  Expanded(
                    flex: 55,
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate logo size - use most of available space
                          // On tablet: fill ~60% width, maintain 2:1 aspect ratio
                          final logoWidth = constraints.maxWidth * 0.6;
                          final logoHeight = constraints.maxHeight * 0.65;

                          return Image.asset(
                            'assets/images/iko_logo.png',
                            width: logoWidth,
                            height: logoHeight,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback: Draw IKO logo similar to original
                              return Container(
                                width: logoWidth,
                                height: logoHeight,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFF2196F3),
                                      const Color(0xFF1565C0),
                                      const Color(0xFF0D47A1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(logoHeight / 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'IKO',
                                    style: TextStyle(
                                      fontSize: logoHeight * 0.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 8,
                                      fontStyle: FontStyle.italic,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black38,
                                          offset: Offset(3, 3),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // Divider line like in original
                  Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.grey[500]!,
                          Colors.grey[500]!,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Bottom section with module buttons
                  Expanded(
                    flex: 45,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Module icons (3x2 grid) - tablet optimized
                          Column(
                            children: [
                              // First row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                  const SizedBox(width: 40),
                                  _ModuleButton(
                                    icon: Icons.people,
                                    label: 'Klienci',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const CustomersListScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 40),
                                  _ModuleButton(
                                    icon: Icons.description,
                                    label: 'Zamówienia',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const OrdersListScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 25),

                              // Second row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _ModuleButton(
                                    icon: Icons.local_offer,
                                    label: 'Oferty',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const QuotesListScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 40),
                                  _ModuleButton(
                                    icon: Icons.shopping_cart,
                                    label: 'Koszyk',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const CartScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 40),
                                  _ModuleButton(
                                    icon: Icons.folder,
                                    label: 'Schowki',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const SavedCartsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // Powered by text
                          const Text(
                            'Powered by PRODAUT',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
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
      borderRadius: BorderRadius.circular(70),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Outer gray ring with gradient + inner blue circle (matching original tablet style)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[200]!,
                    Colors.grey[350]!,
                    Colors.grey[400]!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 4,
                    offset: const Offset(-2, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF42A5F5), // Lighter blue at top
                      Color(0xFF1976D2), // Medium blue
                      Color(0xFF1565C0), // Darker blue at bottom
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
