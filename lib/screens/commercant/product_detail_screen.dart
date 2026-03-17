// lib/screens/commercant/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../services/review_service.dart';
import '../../utils/constants.dart';
import '../../widgets/product_image.dart';
import '../../widgets/rating_stars.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/notification_icon.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  // 👇 Fonction pour obtenir le statut du stock
  Map<String, dynamic> _getStockStatus(Product product) {
    int stock = product.stockQuantity ?? 0;
    int minAlert = product.minStockAlert ?? 5;

    if (stock <= 0) {
      return {
        'color': Colors.red,
        'icon': Icons.error,
        'label': 'Rupture de stock',
        'message': 'Produit indisponible',
        'available': false
      };
    } else if (stock <= minAlert) {
      return {
        'color': Colors.orange,
        'icon': Icons.warning,
        'label': 'Stock faible',
        'message': 'Plus que $stock en stock',
        'available': true
      };
    } else {
      return {
        'color': Colors.green,
        'icon': Icons.check_circle,
        'label': 'En stock',
        'message': '$stock disponibles',
        'available': true
      };
    }
  }

  // 👇 Fonction pour obtenir la note du fournisseur
  Future<double> _getSupplierRating(int? supplierId) async {
    if (supplierId == null) return 0;
    final reviewService = Provider.of<ReviewService>(context, listen: false);
    await reviewService.getSupplierReviews(supplierId);
    return reviewService.supplierReviews?.supplier.averageRating ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final product = widget.product;
    final cartService = Provider.of<CartService>(context, listen: false);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // 👇 Obtenir le statut du stock
    final stockStatus = _getStockStatus(product);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: Icon(
              isArabic ? Icons.arrow_forward : Icons.arrow_back,
              color: AppColors.textDark,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            product.name,
            style: const TextStyle(
              color: Color(0xFF2D3A4F),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            NotificationIcon(color: const Color(0xFF2D3A4F)),
            // 👇 BOUTON POUR VOIR LES AVIS
            if (product.supplierId != null)
              IconButton(
                icon: const Icon(Icons.star_outline, color: Color(0xFF2D3A4F)),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/merchant/product-reviews',
                    arguments: {'product': product},
                  );
                },
              ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF2D3A4F)),
                  onPressed: () => Navigator.pushNamed(context, '/merchant/cart'),
                ),
                Positioned(
                  right: isArabic ? null : 8,
                  left: isArabic ? 8 : null,
                  top: 8,
                  child: Consumer<CartService>(
                    builder: (context, cartService, child) {
                      if (cartService.totalItems == 0) return const SizedBox();
                      return Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '${cartService.totalItems}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Image
              Container(
                width: double.infinity,
                height: 300,
                color: Colors.white,
                child: ProductImage(
                  productId: product.id,
                  imageUrl: product.imageUrl,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),

              // Informations produit
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom et prix
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3A4F),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (product.isInPromotion)
                                Text(
                                  '${product.listPrice.toStringAsFixed(2)} ${localizations.currency}',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              Text(
                                '${product.currentPrice.toStringAsFixed(2)} ${localizations.currency}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: product.isInPromotion ? Colors.red : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 👇 NOUVEAU: Indicateur de stock
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: stockStatus['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: stockStatus['color'].withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            stockStatus['icon'],
                            color: stockStatus['color'],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stockStatus['label'],
                                  style: TextStyle(
                                    color: stockStatus['color'],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  stockStatus['message'],
                                  style: TextStyle(
                                    color: stockStatus['color'].withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 👇 NOUVEAU: SECTION AVIS DU FOURNISSEUR
                    // 👇 NOUVEAU: SECTION AVIS DU FOURNISSEUR
                    if (product.supplierId != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/merchant/product-reviews',
                            arguments: {'product': product},
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.star,
                                  color: Colors.amber.shade700,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Avis sur le fournisseur',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    FutureBuilder<double>(
                                      future: _getSupplierRating(product.supplierId),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return Text(  // 👈 Enlever const
                                            'Chargement des avis...',
                                            style: TextStyle(fontSize: 12),
                                          );
                                        }
                                        if (snapshot.hasData && snapshot.data! > 0) {
                                          return Row(
                                            children: [
                                              RatingStars(
                                                rating: snapshot.data!,
                                                size: 16,
                                                showNumber: true,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(  // 👈 Enlever const
                                                'Voir tous les avis',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                        return Text(  // 👈 Enlever const
                                          'Soyez le premier à donner votre avis',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.amber.shade700,
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Code produit
                    if (product.defaultCode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              isArabic
                                  ? '${product.defaultCode} :رمز المنتج'
                                  : '${localizations.productCode}: ${product.defaultCode}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2D3A4F),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Fournisseur
                    if (product.supplierName != null)
                      Row(
                        children: [
                          const Icon(Icons.store, size: 20, color: Color(0xFF8A9AA8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? '${product.supplierName} :${localizations.company}'
                                  : '${localizations.company}: ${product.supplierName}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2D3A4F),
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Conditionnement
                    if (product.packaging != null)
                      Row(
                        children: [
                          const Icon(Icons.inventory, size: 20, color: Color(0xFF8A9AA8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? '${product.packaging} :${localizations.packaging}'
                                  : '${localizations.packaging}: ${product.packaging}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2D3A4F),
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Description
                    if (product.description != null && product.description!.isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        localizations.description,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3A4F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D3A4F),
                        ),
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Quantité et bouton Ajouter
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          // Quantité
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                localizations.quantity,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D3A4F),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (_quantity > 1) {
                                        setState(() => _quantity--);
                                      }
                                    },
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: AppColors.primary,
                                  ),
                                  Container(
                                    width: 40,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$_quantity',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      // 👇 Vérifier le stock avant d'augmenter
                                      if (stockStatus['available'] &&
                                          _quantity < (product.stockQuantity ?? 0)) {
                                        setState(() => _quantity++);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Stock insuffisant'),
                                            backgroundColor: Colors.orange,
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: stockStatus['available']
                                        ? AppColors.primary
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Sous-total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                localizations.subtotal,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF8A9AA8),
                                ),
                              ),
                              Text(
                                '${(product.currentPrice * _quantity).toStringAsFixed(2)} ${localizations.currency}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Bouton Ajouter au panier
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: stockStatus['available']
                                  ? () async {
                                final cartService = Provider.of<CartService>(
                                    context,
                                    listen: false
                                );

                                bool success = await cartService.addToCart(
                                    product,
                                    quantity: _quantity
                                );

                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(localizations.addToCart),
                                      backgroundColor: AppColors.success,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          cartService.error ?? localizations.errorOccurred
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                                  : null, // Désactivé si stock indisponible
                              icon: Icon(
                                stockStatus['available']
                                    ? Icons.add_shopping_cart
                                    : Icons.block,
                              ),
                              label: Text(
                                stockStatus['available']
                                    ? localizations.addToCart
                                    : 'Indisponible',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: stockStatus['available']
                                    ? AppColors.primary
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),

                          // 👇 Message si stock faible
                          if (stockStatus['available'] &&
                              product.stockQuantity != null &&
                              product.stockQuantity! < 10)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '⚠️ Plus que ${product.stockQuantity} en stock',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
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
        ),
      ),
    );
  }
}