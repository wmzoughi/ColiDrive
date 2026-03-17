// lib/screens/fournisseur/gestion_produits.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import 'add_edit_product_screen.dart';
import '../../widgets/product_image.dart';
import 'compte_screen.dart';

class GestionProduitsScreen extends StatefulWidget {
  const GestionProduitsScreen({Key? key}) : super(key: key);

  @override
  State<GestionProduitsScreen> createState() => _GestionProduitsScreenState();
}

class _GestionProduitsScreenState extends State<GestionProduitsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedCategory;
  bool _showPromoOnly = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final productService = Provider.of<ProductService>(context, listen: false);
    await productService.loadCategories();
    await productService.loadSupplierProducts(reset: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final productService = Provider.of<ProductService>(context, listen: false);
      if (!productService.isLoading && productService.hasMore) {
        productService.loadSupplierProducts(
          search: _searchController.text,
          categoryId: _selectedCategory != null ? int.tryParse(_selectedCategory!) : null,
        );
      }
    }
  }

  void _searchProducts() {
    final productService = Provider.of<ProductService>(context, listen: false);
    productService.loadSupplierProducts(
      search: _searchController.text,
      categoryId: _selectedCategory != null ? int.tryParse(_selectedCategory!) : null,
      reset: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final productService = Provider.of<ProductService>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Image.asset(
              'assets/icons/logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 150,
                  height: 150,
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
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),

      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _searchProducts(),
                      decoration: InputDecoration(
                        hintText: localizations.search,
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: AppColors.primary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.tune, color: AppColors.primary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text(localizations.all),
                          selected: _selectedCategory == null && !_showPromoOnly,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = null;
                              _showPromoOnly = false;
                            });
                            _searchProducts();
                          },
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: (_selectedCategory == null && !_showPromoOnly)
                                ? Colors.white
                                : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(localizations.inPromotion),
                          selected: _showPromoOnly,
                          onSelected: (selected) {
                            setState(() {
                              _showPromoOnly = selected;
                              if (selected) _selectedCategory = null;
                            });
                            _searchProducts();
                          },
                          selectedColor: Colors.orange,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: _showPromoOnly ? Colors.white : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...productService.categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category.name),
                              selected: _selectedCategory == category.id.toString(),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = selected ? category.id.toString() : null;
                                  if (selected) _showPromoOnly = false;
                                });
                                _searchProducts();
                              },
                              selectedColor: AppColors.primary,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: _selectedCategory == category.id.toString()
                                    ? Colors.white
                                    : AppColors.textDark,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditProductScreen(
                          categories: productService.categories,
                          onProductAdded: _loadData,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(localizations.add),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: productService.isLoading && productService.products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : productService.products.isEmpty
                ? Center(
              child: Text(
                localizations.noProducts,
                style: const TextStyle(color: Color(0xFF8A9AA8)),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: productService.products.length + (productService.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == productService.products.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final product = productService.products[index];
                return _buildProductCard(product, productService);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/supplier/dashboard');
          } else if (index == 1) {
             Navigator.pushNamed(context, '/supplier/orders');
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CompteScreenS(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildProductCard(Product product, ProductService service) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          ProductImage(
            productId: product.id,
            imageUrl: product.imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D3A4F),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (product.isInPromotion)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          localizations.inPromotion,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (product.defaultCode != null)
                  Text(
                    product.defaultCode!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${localizations.add}: ',
                              style: const TextStyle(
                                color: Color(0xFF8A9AA8),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              service.formatMAD(product.currentPrice, context),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (product.packaging != null)
                          Text(
                            product.packaging!,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: Color(0xFF4361EE)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditProductScreen(
                                  product: product,
                                  categories: service.categories,
                                  onProductAdded: _loadData,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          onPressed: () => _showDeleteDialog(product, service),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Product product, ProductService service) {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.logout),
          content: Text('${localizations.logoutConfirm} "${product.name}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await service.deleteProduct(product.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations.confirm),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(localizations.confirm),
            ),
          ],
        );
      },
    );
  }
}