// lib/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/review_service.dart';
import '../utils/constants.dart';
import 'product_image.dart';
import 'rating_stars.dart';
import '../l10n/app_localizations.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool showSupplier;
  final bool showAddButton;
  final double? width;
  final double? height;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.showSupplier = true,
    this.showAddButton = true,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 160,
        height: height ?? 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            // Image avec badge promotion
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: ProductImage(
                    productId: product.id,
                    imageUrl: product.imageUrl,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                if (product.isInPromotion)
                  Positioned(
                    top: 8,
                    right: isArabic ? null : 8,
                    left: isArabic ? 8 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '-${product.discountPercentage}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Badge de stock
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: _buildStockBadge(),
                ),
              ],
            ),

            // Informations produit
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du produit
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2D3A4F),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Fournisseur
                  if (showSupplier && product.supplierName != null)
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 10,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            product.supplierName!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),

                  // ✅ AJOUT : Note moyenne du fournisseur
                  FutureBuilder<double>(
                    future: _getSupplierRating(context, product.supplierId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data! > 0) {
                        return Row(
                          children: [
                            RatingStars(
                              rating: snapshot.data!,
                              size: 10,
                              showNumber: true,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${snapshot.data!.toStringAsFixed(1)})',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox(height: 14); // Espace réservé
                    },
                  ),
                  const SizedBox(height: 4),

                  // Conditionnement
                  if (product.packaging != null)
                    Row(
                      children: [
                        Icon(
                          Icons.inventory,
                          size: 10,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            product.packaging!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),

                  // Prix
                  Row(
                    children: [
                      if (product.isInPromotion)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            '${product.listPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 11,
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

                  // Bouton Ajouter au panier
                  if (showAddButton)
                    Consumer<CartService>(
                      builder: (context, cartService, child) {
                        final isInCart = cartService.items.any(
                                (item) => item.product.id == product.id
                        );

                        return SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (isInCart) {
                                Navigator.pushNamed(context, '/merchant/cart');
                              } else {
                                bool success = await cartService.addToCart(
                                  product,
                                  quantity: 1,
                                );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${product.name} ajouté au panier',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInCart ? Colors.green : AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isInCart ? 'Au panier' : localizations.add,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<double> _getSupplierRating(BuildContext context, int? supplierId) async {
    if (supplierId == null) return 0;
    final reviewService = Provider.of<ReviewService>(context, listen: false);
    await reviewService.getSupplierReviews(supplierId);
    return reviewService.supplierReviews?.supplier.averageRating ?? 0;
  }

  // Badge de stock
  Widget _buildStockBadge() {
    if (product.stockQuantity == null) return const SizedBox();

    Color badgeColor;
    String badgeText;

    if (product.stockQuantity! <= 0) {
      badgeColor = Colors.red;
      badgeText = 'Rupture';
    } else if (product.stockQuantity! <= (product.minStockAlert ?? 5)) {
      badgeColor = Colors.orange;
      badgeText = 'Stock faible';
    } else {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        badgeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}