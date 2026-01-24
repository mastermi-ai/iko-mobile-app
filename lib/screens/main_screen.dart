import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cart_cubit.dart';
import '../models/user.dart';
import 'dashboard_screen.dart';
import 'products_list_screen.dart';
import 'customers_list_screen.dart';
import 'cart_screen.dart';

/// Główny ekran z BottomNavigationBar
/// Pozwala szybko przełączać między: Dashboard, Produkty, Klienci, Koszyk
class MainScreen extends StatefulWidget {
  final User user;
  final int initialIndex;

  const MainScreen({
    super.key,
    required this.user,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(user: widget.user),
          const ProductsListScreen(),
          const CustomersListScreen(),
          const CartScreen(),
        ],
      ),
      bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
        builder: (context, cartState) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: Colors.blue[700],
              unselectedItemColor: Colors.grey[600],
              selectedFontSize: 12,
              unselectedFontSize: 12,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  activeIcon: Icon(Icons.home, size: 28),
                  label: 'Start',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2),
                  activeIcon: Icon(Icons.inventory_2, size: 28),
                  label: 'Produkty',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  activeIcon: Icon(Icons.people, size: 28),
                  label: 'Klienci',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: cartState.itemCount > 0,
                    label: Text(
                      '${cartState.itemCount}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    child: const Icon(Icons.shopping_cart),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: cartState.itemCount > 0,
                    label: Text(
                      '${cartState.itemCount}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    child: const Icon(Icons.shopping_cart, size: 28),
                  ),
                  label: 'Koszyk',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
