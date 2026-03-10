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

class DashboardCommercant extends StatefulWidget {
  const DashboardCommercant({Key? key}) : super(key: key);

  @override
  State<DashboardCommercant> createState() => _DashboardCommercantState();
}

class _DashboardCommercantState extends State<DashboardCommercant> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final merchantService = Provider.of<MerchantService>(context, listen: false);
    await merchantService.loadDashboardData();
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

    return Scaffold(
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
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF2D3A4F)),
            onPressed: () {},
          ),
          IconButton(
            icon: CartIconWithBadge(),
            onPressed: () => Navigator.pushNamed(context, '/merchant/cart'),
          ),
        ],
      ),
      body: merchantService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${localizations.hello}, ${user?.name ?? ''}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3A4F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.promotions,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
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
              _buildCreditCard(merchantService),
              const SizedBox(height: 20),
              _buildPromoCard(),
              const SizedBox(height: 24),
              _buildSectionHeader(
                title: localizations.mostOrderedProducts,
                onSeeAll: () => Navigator.pushNamed(context, '/merchant/products'),
              ),
              const SizedBox(height: 16),
              if (merchantService.popularProducts.isEmpty)
                _buildEmptyState(localizations.noProducts)
              else
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: merchantService.popularProducts.length,
                    itemBuilder: (context, index) {
                      final product = merchantService.popularProducts[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < merchantService.popularProducts.length - 1 ? 12 : 0,
                        ),
                        child: _buildProductCard(product),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              _buildSectionHeader(
                title: localizations.recentOrders,
                onSeeAll: () => Navigator.pushNamed(context, '/merchant/orders'),
              ),
              const SizedBox(height: 16),
              if (merchantService.recentOrders.isEmpty)
                _buildEmptyState(localizations.noOrders)
              else
                ...merchantService.recentOrders.map((order) {
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
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            Navigator.pushNamed(context, '/merchant/orders');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/merchant/products');
          } else if (index == 3) { // Panier
            Navigator.pushNamed(context, '/merchant/cart');
          } else if (index == 4) { // Compte
            Navigator.pushNamed(context, '/merchant/account');
          }
        },
      ),
    );
  }

  Widget _buildCreditCard(MerchantService service) {
    final localizations = AppLocalizations.of(context)!;
    final creditBalance = service.creditBalance;
    final creditLimit = service.creditLimit;
    final percentage = service.creditUsagePercentage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
              Row(
                children: [
                  Icon(
                    percentage > 70 ? Icons.trending_up : Icons.trending_down,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    percentage > 70 ? '🔼' : '🔽',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  localizations.seeBalance,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage > 90 ? Colors.red :
                      percentage > 70 ? Colors.orange : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${localizations.minimumThreshold} : ${service.formatMAD(creditLimit, context)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard() {
    final localizations = AppLocalizations.of(context)!;

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      localizations.promotions,
                      style: const TextStyle(
                        color: Color(0xFF2D3A4F),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.promotions,
                  style: const TextStyle(
                    color: Color(0xFF8A9AA8),
                    fontSize: 13,
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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                localizations.seePromos,
                style: TextStyle(
                  color: AppColors.primary,
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

  Widget _buildSectionHeader({required String title, required VoidCallback onSeeAll}) {
    final localizations = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF2D3A4F),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.trending_up,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: onSeeAll,
          child: Text(
            localizations.seeAll,
            style: const TextStyle(
              color: Color(0xFF4361EE),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      width: 150,
      height: 240,
      padding: const EdgeInsets.all(10),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImage(
                productId: product.id,
                imageUrl: product.imageUrl,
                width: double.infinity,
                height: 80,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 6),
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3A4F),
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                product.packaging ?? '',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF8A9AA8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.isInPromotion)
                    Text(
                      '${product.listPrice.toStringAsFixed(2)} MAD',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 9,
                      ),
                    ),
                  Text(
                    '${product.currentPrice.toStringAsFixed(2)} MAD',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: product.isInPromotion ? Colors.red : AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 30,
                child: ElevatedButton(
                  onPressed: () {
                    print('${localizations.add} ${product.name}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    localizations.add,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final localizations = AppLocalizations.of(context)!;

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
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2D3A4F),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: order.isPaid
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.isPaid ? localizations.paid : localizations.unpaid,
                      style: TextStyle(
                        fontSize: 10,
                        color: order.isPaid ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${order.amountTotal.toStringAsFixed(3)} MAD',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3A4F),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF8A9AA8)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.store,
                        color: AppColors.primary,
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.supplierName ?? localizations.company,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2D3A4F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '3 ${localizations.products}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF8A9AA8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF8A9AA8),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}