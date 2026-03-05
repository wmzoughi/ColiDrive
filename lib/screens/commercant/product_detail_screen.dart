// lib/screens/commercant/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/product_image.dart';
import '../../l10n/app_localizations.dart';

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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final product = widget.product;
    final cartService = Provider.of<CartService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF2D3A4F)),
                onPressed: () => Navigator.pushNamed(context, '/merchant/cart'),
              ),
              Positioned(
                right: 8,
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
                            '${localizations.productCode}: ${product.defaultCode}',
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
                        Text(
                          '${localizations.company}: ${product.supplierName}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D3A4F),
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
                        Text(
                          '${localizations.packaging}: ${product.packaging}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D3A4F),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quantité',
                              style: TextStyle(
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
                                    setState(() => _quantity++);
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: AppColors.primary,
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
                            const Text(
                              'Sous-total',
                              style: TextStyle(
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
                            onPressed: () {
                              cartService.addToCart(product, quantity: _quantity);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${localizations.add} au panier'),
                                  backgroundColor: AppColors.success,
                                  duration: const Duration(seconds: 2),
                                ),
                              );

                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.add_shopping_cart),
                            label: Text(
                              '${localizations.add} au panier',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
    );
  }
}