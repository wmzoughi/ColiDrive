// lib/screens/commercant/products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../services/merchant_service.dart';
import '../../utils/constants.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../widgets/product_image.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../l10n/app_localizations.dart';
import 'compte_screen.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tout';
  String _selectedCategoryId = '';
  String _selectedSort = '';
  int _currentPage = 1;
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isLoadingCategories = false;
  final ScrollController _scrollController = ScrollController();

  List<String> _sortOptions = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final merchantService = Provider.of<MerchantService>(context, listen: false);

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/categories'),
        headers: {
          'Authorization': 'Bearer ${merchantService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _categories = (data['data'] as List)
                .map((c) => Category.fromJson(c))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    } finally {
      setState(() => _isLoadingCategories = false);
      // Charger les produits après les catégories
      _loadProducts();
    }
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      _products = [];
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final merchantService = Provider.of<MerchantService>(context, listen: false);
      final localizations = AppLocalizations.of(context)!;

      String url = '${AppConstants.baseUrl}/products?page=$_currentPage&per_page=20';

      if (_searchController.text.isNotEmpty) {
        url += '&search=${_searchController.text}';
      }

      // Filtre par catégorie
      if (_selectedCategoryId.isNotEmpty) {
        url += '&categ_id=$_selectedCategoryId';
        print('🎯 Filtre par catégorie ID: $_selectedCategoryId');
      }

      // Appliquer le tri
      if (_selectedSort == localizations.sortBestSelling) {
        url += '&order_by=popular_rank&order_dir=desc';
      } else if (_selectedSort == localizations.sortPriceAsc) {
        url += '&order_by=list_price&order_dir=asc';
      } else if (_selectedSort == localizations.sortPriceDesc) {
        url += '&order_by=list_price&order_dir=desc';
      } else if (_selectedSort == localizations.sortNewest) {
        url += '&order_by=create_date&order_dir=desc';
      }

      print('🔍 URL: $url');

      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ${merchantService.token}',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List newProducts = data['data']['data'] ?? data['data'] ?? [];

        setState(() {
          _products.addAll(newProducts.map((p) => Product.fromJson(p)).toList());
          _currentPage++;
          _hasMore = newProducts.length == 20;
        });
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
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

  void _searchProducts() {
    _loadProducts(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Initialiser les options de tri avec les traductions
    _sortOptions = [
      localizations.sortBestSelling,
      localizations.sortPriceAsc,
      localizations.sortPriceDesc,
      localizations.sortNewest,
    ];

    // Initialiser la valeur sélectionnée si elle est vide
    if (_selectedSort.isEmpty) {
      _selectedSort = localizations.sortBestSelling;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/icons/logo.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'CD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              'ColiDrive',
              style: TextStyle(
                color: Color(0xFF2D3A4F),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF2D3A4F)),
            onPressed: () => Navigator.pushNamed(context, '/merchant/cart'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _searchProducts(),
                      decoration: InputDecoration(
                        hintText: localizations.search,
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filtres par catégorie
          Container(
            height: 50,
            color: Colors.white,
            child: _isLoadingCategories
                ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedCategoryId.isEmpty;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = '';
                        _selectedCategory = 'Tout';
                      });
                      _loadProducts(reset: true);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          localizations.all,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final category = _categories[index - 1];
                final isSelected = _selectedCategoryId == category.id.toString();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = category.id.toString();
                      _selectedCategory = category.name;
                    });
                    _loadProducts(reset: true);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Tri
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.search,
                  style: const TextStyle(
                    color: Color(0xFF2D3A4F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedSort,
                  items: _sortOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedSort = value);
                      _loadProducts(reset: true);
                    }
                  },
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down),
                ),
              ],
            ),
          ),

          // Liste des produits
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadProducts(reset: true),
              child: _isLoading && _products.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                  ? Center(
                child: Text(
                  localizations.noProducts,
                  style: const TextStyle(color: Color(0xFF8A9AA8)),
                ),
              )
                  : GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _products.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _products.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final product = _products[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(product: product),
                        ),
                      );
                    },
                    child: _buildProductCard(product),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/merchant/dashboard');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/merchant/orders');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/merchant/account');
          }
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductImage(
            productId: product.id,
            imageUrl: product.imageUrl,
            width: double.infinity,
            height: 120,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3A4F),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.packaging ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A9AA8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (product.isInPromotion)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          '${product.listPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    Text(
                      '${product.currentPrice.toStringAsFixed(2)} ${localizations.currency}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: product.isInPromotion ? Colors.red : AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${localizations.min}: 6',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}