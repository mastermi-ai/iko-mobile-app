import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/products_bloc.dart';
import '../../models/product.dart';
import '../../database/database_helper.dart';
import '../../services/api_service.dart';
import 'product_detail_screen.dart';

class ProductsListScreen extends StatelessWidget {
  final bool autoFocusSearch;

  const ProductsListScreen({super.key, this.autoFocusSearch = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductsBloc(
        databaseHelper: DatabaseHelper.instance,
        apiService: ApiService(),
      )..add(LoadProducts()),
      child: ProductsListView(autoFocusSearch: autoFocusSearch),
    );
  }
}

class ProductsListView extends StatefulWidget {
  final bool autoFocusSearch;

  const ProductsListView({super.key, this.autoFocusSearch = false});

  @override
  State<ProductsListView> createState() => _ProductsListViewState();
}

class _ProductsListViewState extends State<ProductsListView> {
  final _searchController = TextEditingController();
  late bool _isSearching;

  @override
  void initState() {
    super.initState();
    _isSearching = widget.autoFocusSearch;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Szukaj produktu...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (query) {
                  context.read<ProductsBloc>().add(SearchProducts(query));
                },
              )
            : const Text('Produkty'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  context.read<ProductsBloc>().add(LoadProducts());
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) {
          if (state is ProductsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ProductsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProductsBloc>().add(LoadProducts());
                    },
                    child: const Text('Spróbuj ponownie'),
                  ),
                ],
              ),
            );
          }

          if (state is ProductsLoaded || state is ProductsRefreshing) {
            final products = state is ProductsLoaded
                ? state.products
                : (state as ProductsRefreshing).currentProducts;

            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Brak produktów',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Zsynchronizuj dane z serwera',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<ProductsBloc>().add(RefreshProducts());
                      },
                      icon: const Icon(Icons.sync),
                      label: const Text('Synchronizuj'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ProductsBloc>().add(RefreshProducts());
                // Wait for the refresh to complete
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: Stack(
                children: [
                  ListView.builder(
                    itemCount: products.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      return ProductCard(
                        product: products[index],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                product: products[index],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  if (state is ProductsRefreshing)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.blue.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(8),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Synchronizacja...'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image_not_supported, size: 40);
                          },
                        ),
                      )
                    : const Icon(Icons.inventory_2, size: 40, color: Colors.grey),
              ),
              const SizedBox(width: 12),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kod: ${product.code}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${product.priceNetto.toStringAsFixed(2)} zł',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'netto',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
