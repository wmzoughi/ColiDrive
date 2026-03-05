// lib/screens/commercant/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/merchant_service.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/product_image.dart';
import '../../l10n/app_localizations.dart';
import '../../models/order.dart';
import '../../l10n/app_localizations.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedIndex = 1;
  String _selectedFilter = '';
  List<Order> _orders = [];
  bool _isLoading = false;

  List<String> _filters = [];

  @override
  void initState() {
    super.initState();
    // Attendre que les localizations soient disponibles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localizations = AppLocalizations.of(context)!;
      setState(() {
        _filters = [
          localizations.filterAll,
          localizations.filterPending,
          localizations.filterConfirmed,
          localizations.filterDelivered,
        ];
        _selectedFilter = localizations.filterAll;
      });
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      final merchantService = Provider.of<MerchantService>(context, listen: false);
      final localizations = AppLocalizations.of(context)!;

      String status = '';
      if (_selectedFilter == localizations.filterPending) {
        status = 'pending';
      } else if (_selectedFilter == localizations.filterConfirmed) {
        status = 'confirmed';
      } else if (_selectedFilter == localizations.filterDelivered) {
        status = 'delivered';
      }

      _orders = await merchantService.getOrders(status: status);
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Réinitialiser les filtres si nécessaire
    if (_filters.isEmpty) {
      _filters = [
        localizations.filterAll,
        localizations.filterPending,
        localizations.filterConfirmed,
        localizations.filterDelivered,
      ];
    }
    if (_selectedFilter.isEmpty) {
      _selectedFilter = localizations.filterAll;
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
              width: 150, // 👈 TAILLE RÉDUITE
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
                        fontSize: 14,
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
          // Filtres traduits
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedFilter = filter);
                    _loadOrders();
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
                        filter,
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

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                ? Center(
              child: Text(
                localizations.noOrders,
                style: const TextStyle(color: Color(0xFF8A9AA8)),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return _buildOrderCard(order);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/merchant/dashboard');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/merchant/products');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/merchant/account');
          }
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
                    child: const Icon(
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
                      fontSize: 16,
                      color: Color(0xFF2D3A4F),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: order.status == 'pending'
                      ? Colors.orange.withOpacity(0.1)
                      : order.status == 'delivered'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: order.status == 'pending'
                        ? Colors.orange
                        : order.status == 'delivered'
                        ? Colors.green
                        : Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.store, size: 14, color: Color(0xFF8A9AA8)),
              const SizedBox(width: 4),
              Text(
                '${localizations.company}: ${order.supplierName ?? localizations.company}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF2D3A4F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Color(0xFF8A9AA8)),
              const SizedBox(width: 4),
              Text(
                _formatDate(order.createdAt, localizations),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A9AA8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...order.items?.take(2).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  ProductImage(
                    productId: item.productId,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: Color(0xFF2D3A4F),
                          ),
                        ),
                        Text(
                          '${item.quantity} x ${item.price.toStringAsFixed(2)} ${localizations.currency}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8A9AA8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.subtotal.toStringAsFixed(2)} ${localizations.currency}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }).toList() ?? [],

          if ((order.items?.length ?? 0) > 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '+ ${order.items!.length - 2} ${localizations.products}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8A9AA8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const Divider(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.totalSales,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A9AA8),
                    ),
                  ),
                  Text(
                    '${order.amountTotal.toStringAsFixed(2)} ${localizations.currency}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (order.status == 'pending')
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(localizations.cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(localizations.confirm),
                    ),
                  ],
                )
              else if (order.status == 'confirmed')
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(localizations.delivered),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, AppLocalizations localizations) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${localizations.timeAgo} ${difference.inDays} ${localizations.days}';
    } else if (difference.inHours > 0) {
      return '${localizations.timeAgo} ${difference.inHours} ${localizations.hours}';
    } else {
      return '${localizations.timeAgo} ${difference.inMinutes} ${localizations.minutes}';
    }
  }
}