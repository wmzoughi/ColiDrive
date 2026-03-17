// lib/screens/commercant/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/product_image.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cart_item.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;

  Future<void> _refreshCart() async {
    setState(() => _isLoading = true);
    final cartService = Provider.of<CartService>(context, listen: false);
    await cartService.loadCart();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final localizations = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Obtenir les articles groupés par fournisseur
    final itemsBySupplier = cartService.getItemsBySupplier();
    final supplierCount = itemsBySupplier.length;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Mon Panier',
            style: const TextStyle(
              color: Color(0xFF2D3A4F),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : cartService.isEmpty
            ? _buildEmptyCart(localizations)
            : RefreshIndicator(
          onRefresh: _refreshCart,
          child: Column(
            children: [
              // En-tête avec nombre de fournisseurs
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    Icon(
                      Icons.store,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      supplierCount > 1
                          ? '$supplierCount fournisseurs dans votre panier'
                          : '1 fournisseur dans votre panier',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3A4F),
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des articles groupés par fournisseur
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: itemsBySupplier.length,
                  itemBuilder: (context, index) {
                    final entry = itemsBySupplier.entries.elementAt(index);
                    return _buildSupplierSection(
                      entry.key,
                      entry.value['supplier_name'],
                      entry.value['items'],
                      entry.value['subtotal'],
                    );
                  },
                ),
              ),

              // Résumé de la commande
              _buildCartSummary(supplierCount, itemsBySupplier),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 4,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/merchant/dashboard');
            } else if (index == 1) {
              Navigator.pushReplacementNamed(context, '/merchant/suppliers');
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, '/merchant/orders');
            } else if (index == 3) {
              Navigator.pushReplacementNamed(context, '/merchant/products');
            } else if (index == 5) {
              Navigator.pushReplacementNamed(context, '/merchant/account');
            }
          },
        ),
      ),
    );
  }

  // Écran panier vide
  Widget _buildEmptyCart(AppLocalizations localizations) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'Votre panier est vide',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Découvrez nos boutiques et ajoutez des produits',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/merchant/dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Découvrir les boutiques',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section d'un fournisseur
  Widget _buildSupplierSection(
      int supplierId,
      String supplierName,
      List<CartItem> items,
      double subtotal,
      ) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du fournisseur
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      supplierName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplierName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D3A4F),
                        ),
                      ),
                      Text(
                        '${items.length} article(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${subtotal.toStringAsFixed(2)} ${localizations.currency}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Liste des articles de ce fournisseur
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildCartItem(item),
          )).toList(),

          // Bouton "Voir la boutique" (optionnel)
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/merchant/supplier-products',
                  arguments: {
                    'supplier_id': supplierId,
                    'supplier_name': supplierName,
                  },
                );
              },
              icon: const Icon(Icons.store, size: 16),
              label: const Text('Voir la boutique'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Article individuel
  Widget _buildCartItem(CartItem item) {
    final localizations = AppLocalizations.of(context)!;
    final cartService = Provider.of<CartService>(context, listen: false);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image du produit
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ProductImage(
            productId: item.product.id,
            imageUrl: item.product.imageUrl,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),

        // Détails du produit
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF2D3A4F),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (item.product.packaging != null)
                Text(
                  item.product.packaging!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A9AA8),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Prix unitaire
                  Text(
                    '${item.product.currentPrice.toStringAsFixed(2)} ${localizations.currency}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 12,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(width: 8),
                  // Sous-total
                  Text(
                    'Sous-total: ${item.totalPrice.toStringAsFixed(2)} ${localizations.currency}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Contrôles de quantité
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              IconButton(
                onPressed: () {
                  cartService.incrementQuantity(item.product.id);
                },
                icon: const Icon(Icons.add, size: 16),
                color: AppColors.primary,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  cartService.decrementQuantity(item.product.id);
                },
                icon: const Icon(Icons.remove, size: 16),
                color: Colors.grey.shade700,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Résumé de la commande
  Widget _buildCartSummary(int supplierCount, Map<int, Map<String, dynamic>> itemsBySupplier) {
    final cartService = Provider.of<CartService>(context);
    final localizations = AppLocalizations.of(context)!;
    final summary = cartService.getCheckoutSummary();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Détail par fournisseur
            ...itemsBySupplier.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.value['supplier_name'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2D3A4F),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${entry.value['subtotal'].toStringAsFixed(2)} ${localizations.currency}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const Divider(height: 24),

            // Sous-total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sous-total',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${summary['subtotal']?.toStringAsFixed(2)} ${localizations.currency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // TVA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TVA (20%)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${summary['tax']?.toStringAsFixed(2)} ${localizations.currency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Frais de livraison
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Frais de livraison',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${summary['shipping']?.toStringAsFixed(2)} ${localizations.currency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF2D3A4F),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        supplierCount > 1 ? '$supplierCount fournisseurs' : '1 fournisseur',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${summary['total']?.toStringAsFixed(2)} ${localizations.currency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Bouton de commande
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  final authService = Provider.of<AuthService>(context, listen: false);
                  if (!authService.isAuthenticated) {
                    Navigator.pushNamed(context, '/login');
                    return;
                  }
                  Navigator.pushNamed(context, '/merchant/checkout');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Passer la commande',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Message informatif
            if (supplierCount > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Votre commande sera divisée en $supplierCount commandes (une par fournisseur)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}