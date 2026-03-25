// lib/screens/commercant/dashboard_commercant.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/merchant_service.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../models/order.dart';
import '../../widgets/product_image.dart';
import '../../widgets/cart_icon_with_badge.dart';
import '../../services/cart_service.dart';
import '../../widgets/notification_icon.dart';
import '../../widgets/invoice_badge.dart';

class DashboardCommercant extends StatefulWidget {
  const DashboardCommercant({Key? key}) : super(key: key);

  @override
  State<DashboardCommercant> createState() => _DashboardCommercantState();
}

class _DashboardCommercantState extends State<DashboardCommercant> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  // Liste des fournisseurs
  List<Map<String, dynamic>> _suppliers = [];
  bool _isLoadingSuppliers = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSuppliers();
  }

  Future<void> _loadData() async {
    final merchantService = Provider.of<MerchantService>(context, listen: false);
    await merchantService.loadDashboardData();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoadingSuppliers = true);
    try {
      final merchantService = Provider.of<MerchantService>(context, listen: false);
      _suppliers = await merchantService.getAvailableSuppliers();
      print('📦 Fournisseurs chargés: ${_suppliers.length}');
    } catch (e) {
      print('❌ Erreur chargement fournisseurs: $e');
    } finally {
      setState(() => _isLoadingSuppliers = false);
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/merchant/products',
        arguments: {'search': query},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final merchantService = Provider.of<MerchantService>(context);
    final user = authService.currentUser;
    final localizations = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
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
          actions: [
            InvoiceBadge(color: const Color(0xFF2D3A4F)),
            NotificationIcon(color: const Color(0xFF2D3A4F)), // 👈 AJOUTEZ ICI
            IconButton(
              icon: CartIconWithBadge(),
              onPressed: () => Navigator.pushNamed(context, '/merchant/cart'),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await _loadData();
            await _loadSuppliers();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message de bienvenue
                Text(
                  '${localizations.hello}, ${user?.name?.split(' ')[0] ?? ''} 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3A4F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prêt à faire vos achats ?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                // Barre de recherche
                InkWell(
                  onTap: () => _onSearchSubmitted(''),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: localizations.search,
                        hintStyle: const TextStyle(color: Color(0xFF8A9AA8)),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF8A9AA8)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Section Fournisseurs
                _buildSuppliersSection(),

                const SizedBox(height: 24),

                // Carte de crédit
                _buildCreditCard(merchantService),

                const SizedBox(height: 20),

                // Carte des promotions
                _buildPromoCard(),

                const SizedBox(height: 24),

                // Produits les plus commandés
                _buildSectionHeader(
                  title: localizations.mostOrderedProducts,
                  onSeeAll: () => Navigator.pushNamed(context, '/merchant/products'),
                ),
                const SizedBox(height: 16),

                if (merchantService.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (merchantService.popularProducts.isEmpty)
                  _buildEmptyState(localizations.noProducts)
                else
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: merchantService.popularProducts.length,
                      itemBuilder: (context, index) {
                        final product = merchantService.popularProducts[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < merchantService.popularProducts.length - 1 ? 12 : 0,
                          ),
                          child: SizedBox(
                            width: 150,
                            child: _buildProductCard(product),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // Commandes récentes
                _buildSectionHeader(
                  title: localizations.recentOrders,
                  onSeeAll: () => Navigator.pushNamed(context, '/merchant/orders'),
                ),
                const SizedBox(height: 16),

                if (merchantService.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (merchantService.recentOrders.isEmpty)
                  _buildEmptyState(localizations.noOrders)
                else
                  ...merchantService.recentOrders.take(3).map((order) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildOrderCard(order),
                    );
                  }).toList(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) {
              Navigator.pushNamed(context, '/merchant/suppliers');
            } else if (index == 2) {
              Navigator.pushNamed(context, '/merchant/orders');
            } else if (index == 3) {
              Navigator.pushNamed(context, '/merchant/products');
            } else if (index == 4) {
              Navigator.pushNamed(context, '/merchant/cart');
            } else if (index == 5) {
              Navigator.pushNamed(context, '/merchant/account');
            }
          },
        ),
      ),
    );
  }

  // SECTION FOURNISSEURS
  Widget _buildSuppliersSection() {
    final localizations = AppLocalizations.of(context)!;

    if (_isLoadingSuppliers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suppliers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.store, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Nos fournisseurs',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3A4F),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                // Voir tous les fournisseurs (optionnel)
              },
              child: Text(
                localizations.seeAll,
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _suppliers.length,
            itemBuilder: (context, index) {
              final supplier = _suppliers[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/merchant/supplier-products',
                    arguments: {
                      'supplier_id': supplier['id'],
                      'supplier_name': supplier['company_name'] ?? supplier['name'],
                    },
                  );
                },
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (supplier['company_name'] ?? supplier['name'])[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        supplier['company_name'] ?? supplier['name'],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '👆 Cliquez sur un fournisseur pour voir ses produits',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // CARTE DE CRÉDIT
  Widget _buildCreditCard(MerchantService service) {
    final localizations = AppLocalizations.of(context)!;
    final creditBalance = service.creditBalance;
    final creditLimit = service.creditLimit;
    final percentage = service.creditUsagePercentage;

    Color getProgressColor() {
      if (percentage > 90) return Colors.red;
      if (percentage > 70) return Colors.orange;
      return Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.globalBalance,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  percentage > 70 ? '⚠️ Élevé' : '✅ Sain',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                service.formatMAD(creditBalance, context),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  localizations.seeBalance,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(getProgressColor()),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${localizations.minimumThreshold} : ${service.formatMAD(creditLimit, context)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // CARTE PROMOTION
  Widget _buildPromoCard() {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.orange,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.promotions,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3A4F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jusqu\'à -50% sur une sélection de produits',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/merchant/products', arguments: {'promo': true});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                localizations.seePromos,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // EN-TÊTE DE SECTION
  Widget _buildSectionHeader({required String title, required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3A4F),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.trending_up,
                size: 14,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
          child: Text(
            'Voir tout',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // CARTE PRODUIT
  // lib/screens/commercant/dashboard_commercant.dart

  Widget _buildProductCard(Product product) {
    final localizations = AppLocalizations.of(context)!;
    final cartService = Provider.of<CartService>(context, listen: false);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/merchant/product-detail',
          arguments: {'product': product},
        );
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // 👈 AJOUTER
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: ProductImage(
                productId: product.id,
                imageUrl: product.imageUrl,
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),

            // Contenu
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // 👈 AJOUTER
                children: [
                  // Nom du produit
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2, // 👈 CHANGER maxLines à 2
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Conditionnement
                  if (product.packaging != null && product.packaging!.isNotEmpty)
                    Text(
                      product.packaging!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 8),

                  // Prix
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
                      Expanded(
                        child: Text(
                          '${product.currentPrice.toStringAsFixed(2)} ${localizations.currency}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: product.isInPromotion ? Colors.red : AppColors.primary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Bouton Ajouter
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () {
                        cartService.addToCart(product, quantity: 1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} ajouté au panier'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Ajouter',
                        style: TextStyle(fontSize: 11),
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

  // CARTE COMMANDE
  Widget _buildOrderCard(Order order) {
    final localizations = AppLocalizations.of(context)!;

    Color getStatusColor() {
      switch (order.status) {
        case 'pending': return Colors.orange;
        case 'confirmed': return Colors.blue;
        case 'preparing': return Colors.purple;
        case 'delivering': return Colors.indigo;
        case 'delivered': return Colors.green;
        case 'cancelled': return Colors.red;
        default: return Colors.grey;
      }
    }

    String getStatusLabel() {
      switch (order.status) {
        case 'pending': return localizations.pending;
        case 'confirmed': return localizations.confirmed;
        case 'preparing': return 'En préparation';
        case 'delivering': return 'En livraison';
        case 'delivered': return localizations.delivered;
        case 'cancelled': return 'Annulée';
        default: return order.status;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  getStatusLabel(),
                  style: TextStyle(
                    fontSize: 10,
                    color: getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.store, size: 14, color: Color(0xFF8A9AA8)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.supplierName ?? 'Fournisseur',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2D3A4F),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${order.items?.length ?? 0} article(s)',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8A9AA8),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.total,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8A9AA8),
                ),
              ),
              Text(
                '${order.amountTotal.toStringAsFixed(2)} ${localizations.currency}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ÉTAT VIDE
  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}