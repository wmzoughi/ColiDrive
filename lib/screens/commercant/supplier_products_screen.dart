// lib/screens/commercant/supplier_products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../utils/constants.dart';
import '../../widgets/product_card.dart';
import '../../l10n/app_localizations.dart';

class SupplierProductsScreen extends StatefulWidget {
  final int supplierId;
  final String supplierName;

  const SupplierProductsScreen({
    Key? key,
    required this.supplierId,
    required this.supplierName,
  }) : super(key: key);

  @override
  State<SupplierProductsScreen> createState() => _SupplierProductsScreenState();
}

class _SupplierProductsScreenState extends State<SupplierProductsScreen> {
  List<Product> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final productService = Provider.of<ProductService>(context, listen: false);
      final newProducts = await productService.getProductsBySupplier(
        widget.supplierId,
        page: _currentPage,
      );

      setState(() {
        if (newProducts.isEmpty) {
          _hasMore = false;
        } else {
          _products.addAll(newProducts);
          _currentPage++;
        }
      });
    } catch (e) {
      print('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadProducts();
    }
  }

  String _getProductCountText(int count, AppLocalizations localizations) {
    if (count == 0) {
      return '0 ${localizations.products}';
    } else if (count == 1) {
      return '1 ${localizations.product}';
    } else {
      return '$count ${localizations.products}';
    }
  }

  String _getCartText(int totalItems, AppLocalizations localizations) {
    if (totalItems == 0) {
      return localizations.cart;
    } else {
      return '${localizations.cart} ($totalItems)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3A4F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.supplierName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3A4F),
              ),
            ),
            Text(
              _getProductCountText(_products.length, localizations),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      body: _products.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _products.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return ProductCard(
            product: _products[index],
            onTap: () {
              Navigator.pushNamed(
                context,
                '/merchant/product-detail',
                arguments: {'product': _products[index]},
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/merchant/cart');
        },
        icon: const Icon(Icons.shopping_cart),
        label: Consumer<CartService>(
          builder: (context, cartService, child) {
            int totalItems = cartService.totalItems;
            return Text(_getCartText(totalItems, localizations));
          },
        ),
        backgroundColor: AppColors.greyLight,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}