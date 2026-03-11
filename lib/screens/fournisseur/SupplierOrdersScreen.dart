// lib/screens/fournisseur/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/product_image.dart';
import '../../l10n/app_localizations.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';

class SupplierOrdersScreen extends StatefulWidget {
  const SupplierOrdersScreen({Key? key}) : super(key: key);

  @override
  State<SupplierOrdersScreen> createState() => _SupplierOrdersScreenState();
}

class _SupplierOrdersScreenState extends State<SupplierOrdersScreen> {
  int _selectedIndex = 1;
  String _selectedFilter = '';
  List<Order> _orders = [];
  bool _isLoading = false;
  Map<String, dynamic>? _stats;

  List<String> _filters = [];

  // ✅ ID du fournisseur connecté
  int? get _currentSupplierId {
    final authService = Provider.of<AuthService>(context, listen: false);
    return authService.currentUser?.id;
  }

  // ✅ Filtrer les items du fournisseur

  List<OrderItem> _getSupplierItems(Order order) {
    if (order.items == null) {
      print('❌ order.items est null');
      return [];
    }

    final supplierId = _currentSupplierId;
    if (supplierId == null) {
      print('❌ supplierId est null');
      return [];
    }

    print('🔍 Fournisseur connecté ID: $supplierId');
    print('📦 Commande: ${order.orderNumber}');
    print('   Total items dans commande: ${order.items!.length}');

    List<OrderItem> filtered = [];

    for (var item in order.items!) {
      int? itemSupplierId = item.productSnapshot?['supplier_id'];
      print('   - Produit: ${item.productName}');
      print('     supplier_id dans snapshot: $itemSupplierId');
      print('     correspond? ${itemSupplierId == supplierId}');

      if (itemSupplierId == supplierId) {
        filtered.add(item);
      }
    }

    print('   ✅ Items filtrés: ${filtered.length}');
    return filtered;
  }
  // ✅ VERSION CORRECTE
  double _getSupplierTotal(Order order) {
    final supplierItems = _getSupplierItems(order);
    return supplierItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localizations = AppLocalizations.of(context)!;
      setState(() {
        _filters = [
          localizations.filterAll,
          localizations.filterPending,
          localizations.filterConfirmed,
          localizations.filterPreparing,
          localizations.filterDelivering,
          localizations.filterDelivered,
          localizations.filterCancelled,
        ];
        _selectedFilter = localizations.filterAll;
      });
      _loadOrders();
      _loadStats();
    });
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      final localizations = AppLocalizations.of(context)!;

      String status = '';
      if (_selectedFilter == localizations.filterPending) {
        status = 'pending';
      } else if (_selectedFilter == localizations.filterConfirmed) {
        status = 'confirmed';
      } else if (_selectedFilter == localizations.filterPreparing) {
        status = 'preparing';
      } else if (_selectedFilter == localizations.filterDelivering) {
        status = 'delivering';
      } else if (_selectedFilter == localizations.filterDelivered) {
        status = 'delivered';
      } else if (_selectedFilter == localizations.filterCancelled) {
        status = 'cancelled';
      }

      _orders = await orderService.getMyOrders(status: status);
      print('📦 Commandes chargées: ${_orders.length}');
    } catch (e) {
      debugPrint('❌ Error loading orders: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorOccurred}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      final stats = await orderService.getOrderStats();

      print('📊 Stats reçues: $stats');

      setState(() {
        _stats = stats;
      });
    } catch (e) {
      debugPrint('❌ Error loading stats: $e');
    }
  }

  // ✅ Méthode pour confirmer une commande
  Future<void> _confirmOrder(Order order) async {
    final localizations = AppLocalizations.of(context)!;

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.confirmOrder),
          content: Text('${localizations.confirmOrderMessage} ${order.orderNumber} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text(localizations.confirm),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final success = await orderService.confirmOrder(order.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${localizations.orderConfirmed}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders();
        _loadStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${localizations.errorOccurred}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Méthode pour passer en préparation
  Future<void> _prepareOrder(Order order) async {
    final localizations = AppLocalizations.of(context)!;

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Passer en préparation'),
          content: Text('Confirmer le passage en préparation de la commande ${order.orderNumber} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text(localizations.preparing),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final success = await orderService.prepareOrder(order.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Commande en préparation'),
            backgroundColor: Colors.blue,
          ),
        );
        _loadOrders();
        _loadStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${localizations.errorOccurred}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Méthode pour démarrer la livraison
  Future<void> _startDelivery(Order order) async {
    final localizations = AppLocalizations.of(context)!;

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Mettre en livraison'),
          content: Text('Confirmer la mise en livraison de la commande ${order.orderNumber} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Text(localizations.delivering),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final success = await orderService.deliverOrder(order.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Commande en cours de livraison'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadOrders();
        _loadStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${localizations.errorOccurred}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Méthode pour marquer comme livrée
  Future<void> _markAsDelivered(Order order) async {
    final localizations = AppLocalizations.of(context)!;

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirmer la livraison'),
          content: Text('Marquer la commande ${order.orderNumber} comme livrée ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text(localizations.delivered),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final success = await orderService.deliverOrder(order.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Commande livrée'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders();
        _loadStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${localizations.errorOccurred}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Méthode pour annuler une commande
  Future<void> _cancelOrder(Order order) async {
    final localizations = AppLocalizations.of(context)!;
    final TextEditingController reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.cancelOrder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${localizations.order}: ${order.orderNumber}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: localizations.cancellationReason,
                hintText: localizations.cancellationReasonHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.back),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context, reasonController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(localizations.cancelOrder),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      final success = await orderService.cancelOrder(order.id, reason);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${localizations.orderCancelled}'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadOrders();
        _loadStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${localizations.errorOccurred}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  Color _getStatusColor(Order order) {
    return order.statusColor;
  }

  String _getStatusLabel(Order order, AppLocalizations localizations) {
    switch (order.status) {
      case 'pending': return localizations.pending;
      case 'confirmed': return localizations.confirmed;
      case 'preparing': return localizations.preparing;
      case 'delivering': return localizations.delivering;
      case 'delivered': return localizations.delivered;
      case 'cancelled': return localizations.cancelled;
      default: return order.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (_filters.isEmpty) {
      _filters = [
        localizations.filterAll,
        localizations.filterPending,
        localizations.filterConfirmed,
        localizations.filterPreparing,
        localizations.filterDelivering,
        localizations.filterDelivered,
        localizations.filterCancelled,
      ];
    }
    if (_selectedFilter.isEmpty) {
      _selectedFilter = localizations.filterAll;
    }

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.supplierOrders,
                style: const TextStyle(
                  color: Color(0xFF2D3A4F),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (user?.companyName != null)
                Text(
                  user!.companyName!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF2D3A4F)),
              onPressed: () {
                _loadOrders();
                _loadStats();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (_stats != null) _buildStatsCard(localizations, isArabic),

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.noOrders,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return _buildOrderCard(order, localizations, isArabic);
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/supplier/dashboard');
            } else if (index == 1) {
              // Déjà sur les commandes
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, '/supplier/products');
            } else if (index == 3) {
              Navigator.pushReplacementNamed(context, '/supplier/account');
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatsCard(AppLocalizations localizations, bool isArabic) {
    double totalRevenue = _toDouble(_stats?['total_revenue']);
    int pendingOrders = _toInt(_stats?['pending_orders']);
    int confirmedOrders = _toInt(_stats?['confirmed_orders']);
    int preparingOrders = _toInt(_stats?['preparing_orders']);
    int deliveringOrders = _toInt(_stats?['delivering_orders']);
    int deliveredOrders = _toInt(_stats?['delivered_orders']);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Première ligne
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                localizations.pending,
                pendingOrders.toString(),
                Icons.pending_actions,
                Colors.orange,
                isArabic,
              ),
              _buildStatItem(
                localizations.confirmed,
                confirmedOrders.toString(),
                Icons.check_circle,
                Colors.green,
                isArabic,
              ),
              _buildStatItem(
                localizations.preparing,
                preparingOrders.toString(),
                Icons.build,
                Colors.purple,
                isArabic,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Deuxième ligne
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                localizations.delivering,
                deliveringOrders.toString(),
                Icons.local_shipping,
                Colors.blue,
                isArabic,
              ),
              _buildStatItem(
                localizations.delivered,
                deliveredOrders.toString(),
                Icons.check_circle,
                Colors.teal,
                isArabic,
              ),
              _buildStatItem(
                localizations.totalRevenue,
                '${totalRevenue.toStringAsFixed(2)} ${localizations.currency}',
                Icons.attach_money,
                Colors.yellow,
                isArabic,
                isLarge: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isArabic, {bool isLarge = false}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: isLarge ? 28 : 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isLarge ? 20 : 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isLarge ? 14 : 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ✅ Carte de commande avec filtrage
  Widget _buildOrderCard(Order order, AppLocalizations localizations, bool isArabic) {
    final supplierItems = _getSupplierItems(order);
    final supplierTotal = _getSupplierTotal(order);
    const int maxDisplayItems = 10;
    print('🟢 Construction carte pour ${order.orderNumber}');
    print('   supplierItems.length = ${supplierItems.length}');
    print('   supplierTotal = $supplierTotal');

    if (supplierItems.isEmpty) {
      print('   ❌ Carte cachée (aucun item)');
      return const SizedBox.shrink();
    }

    print('   ✅ Carte affichée avec ${supplierItems.length} items');
    if (supplierItems.isEmpty) return const SizedBox.shrink();

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
          // En-tête
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
                      Icons.receipt_outlined,
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
                  color: _getStatusColor(order).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(order, localizations),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(order),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Client
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Color(0xFF8A9AA8)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${localizations.client}: ${order.customerDisplayName}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2D3A4F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Color(0xFF8A9AA8)),
              const SizedBox(width: 4),
              Text(
                _formatDate(order.createdAt, localizations, isArabic),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A9AA8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Produits du fournisseur
          ...supplierItems.take(maxDisplayItems).map((item) {
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
          }).toList(),

          if (supplierItems.length > maxDisplayItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '+ ${supplierItems.length - maxDisplayItems} ${localizations.moreProducts}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8A9AA8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const Divider(height: 20),

          // Total et boutons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total (vos produits)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A9AA8),
                    ),
                  ),
                  Text(
                    '${supplierTotal.toStringAsFixed(2)} ${localizations.currency}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Row(
                children: _buildActionButtons(order, localizations, isArabic),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(Order order, AppLocalizations localizations, bool isArabic) {
    List<Widget> buttons = [];

    switch (order.status) {
      case 'pending':
        buttons = [
          OutlinedButton(
            onPressed: () => _cancelOrder(order),
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
            onPressed: () => _confirmOrder(order),
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
        ];
        break;

      case 'confirmed':
        buttons = [
          OutlinedButton(
            onPressed: () => _cancelOrder(order),
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
            onPressed: () => _prepareOrder(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(localizations.preparing),
          ),
        ];
        break;

      case 'preparing':
        buttons = [
          ElevatedButton(
            onPressed: () => _startDelivery(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(localizations.delivering),
          ),
        ];
        break;

      case 'delivering':
        buttons = [
          ElevatedButton(
            onPressed: () => _markAsDelivered(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(localizations.delivered),
          ),
        ];
        break;

      default:
        buttons = [];
    }

    return buttons;
  }

  String _formatDate(DateTime date, AppLocalizations localizations, bool isArabic) {
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