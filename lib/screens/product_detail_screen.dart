import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/product.dart';
import '../../bloc/cart_cubit.dart';
import '../../widgets/app_notification.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Get list of images (currently just one, but ready for multiple)
  List<Widget> _buildImageList() {
    final images = <Widget>[];

    // Add main thumbnail if exists
    if (widget.product.thumbnailBase64 != null &&
        widget.product.thumbnailBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(widget.product.thumbnailBase64!);
        images.add(
          Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          ),
        );
      } catch (e) {
        images.add(_buildPlaceholder());
      }
    } else if (widget.product.imageUrl != null &&
        widget.product.imageUrl!.isNotEmpty) {
      images.add(
        Image.network(
          widget.product.imageUrl!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ),
      );
    }

    // If no images, add placeholder
    if (images.isEmpty) {
      images.add(_buildPlaceholder());
    }

    return images;
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        Icons.inventory_2,
        size: 100,
        color: Colors.grey,
      ),
    );
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _showQuantityDialog() {
    final controller = TextEditingController(text: '$_quantity');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Podaj ilość'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Ilość',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final qty = int.tryParse(value);
            if (qty != null && qty > 0) {
              setState(() => _quantity = qty);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(controller.text);
              if (qty != null && qty > 0) {
                setState(() => _quantity = qty);
                Navigator.pop(context);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addToCart(BuildContext context) {
    context.read<CartCubit>().addProduct(widget.product, quantity: _quantity);
    AppNotification.cartAdded(context, widget.product.name, quantity: _quantity);
    setState(() {
      _quantity = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final images = _buildImageList();
    final hasMultipleImages = images.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły produktu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () => _addToCart(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey[200],
              child: Stack(
                children: [
                  // PageView for swiping images
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: images[index],
                      );
                    },
                  ),

                  // Page indicator dots (only if multiple images)
                  if (hasMultipleImages)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (index) => Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? Colors.blue[700]
                                  : Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Image counter (only if multiple images)
                  if (hasMultipleImages)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Product Code
                  Text(
                    'Kod: ${widget.product.code}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (widget.product.ean != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'EAN: ${widget.product.ean}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Price Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cena',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Netto:'),
                              Text(
                                '${widget.product.priceNetto.toStringAsFixed(2)} zł',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          if (widget.product.priceBrutto != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Brutto:'),
                                Text(
                                  '${widget.product.priceBrutto!.toStringAsFixed(2)} zł',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (widget.product.vatRate != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('VAT:'),
                                Text(
                                  '${widget.product.vatRate!.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Unit
                  Row(
                    children: [
                      const Text(
                        'Jednostka: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(widget.product.unit),
                    ],
                  ),

                  // Description
                  if (widget.product.description != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Opis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product.description!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Quantity Selector - improved UX
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Ilość:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Minus button - 48x48 touch target
                        Material(
                          color: _quantity > 1 ? Colors.blue[700] : Colors.grey[400],
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: _quantity > 1 ? _decrementQuantity : null,
                            borderRadius: BorderRadius.circular(8),
                            child: const SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(
                                Icons.remove,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        // Quantity display - tappable to enter manually
                        GestureDetector(
                          onTap: _showQuantityDialog,
                          child: Container(
                            width: 80,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Plus button - 48x48 touch target
                        Material(
                          color: Colors.blue[700],
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: _incrementQuantity,
                            borderRadius: BorderRadius.circular(8),
                            child: const SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Summary (total for selected quantity)
                  if (_quantity > 1)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Razem (x$_quantity):',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                            ),
                          ),
                          Text(
                            '${(widget.product.priceNetto * _quantity).toStringAsFixed(2)} zł netto',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _addToCart(context),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(
                        _quantity > 1
                            ? 'Dodaj $_quantity szt. do koszyka'
                            : 'Dodaj do koszyka',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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
}
