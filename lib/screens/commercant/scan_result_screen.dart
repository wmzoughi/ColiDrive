// lib/screens/commercant/scan_result_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/barcode_service.dart';
import '../../services/cart_service.dart';
import '../../models/product_offer.dart';
import '../../widgets/product_image.dart';
import '../../utils/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product.dart';


class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({Key? key}) : super(key: key);

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  ProductOffer? _selectedOffer;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final barcodeService = Provider.of<BarcodeService>(context);
    final cartService = Provider.of<CartService>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;
    final scannedProduct = barcodeService.scannedProduct;

    if (scannedProduct == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Résultat du scan'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                barcodeService.error ?? 'Produit non trouvé',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vérifiez le code-barres et réessayez',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Scanner à nouveau'),
              ),
            ],
          ),
        ),
      );
    }

    final allOffers = scannedProduct.getAllOffers();
    _selectedOffer ??= allOffers.first;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Produit scanné',
          style: TextStyle(
            color: Color(0xFF2D3A4F),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3A4F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image et informations produit
            Container(
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ProductImage(
                      productId: scannedProduct.id,
                      imageUrl: scannedProduct.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scannedProduct.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (scannedProduct.packaging != null)
                          Text(
                            scannedProduct.packaging!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Code: ${scannedProduct.barcode}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section comparaison des prix
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.compare_arrows, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Comparer les offres',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Liste des offres
                  ...allOffers.map((offer) {
                    final isSelected = _selectedOffer?.supplierId == offer.supplierId;
                    return _buildOfferCard(offer, isSelected, localizations);
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section quantité et ajout au panier
            if (_selectedOffer != null)
              Container(
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
                                if (_selectedOffer!.isInStock &&
                                    _quantity < _selectedOffer!.stock) {
                                  setState(() => _quantity++);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Stock insuffisant'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sous-total',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${(_selectedOffer!.price * _quantity).toStringAsFixed(2)} ${localizations.currency}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 140,
                          height: 45,
                          child: ElevatedButton.icon(
                            // Dans scan_result_screen.dart, remplacez le TODO par :

                            onPressed: () async {
                              if (_selectedOffer == null) return;

                              final cartService = Provider.of<CartService>(context, listen: false);
                              final barcodeService = Provider.of<BarcodeService>(context, listen: false);
                              final scannedProduct = barcodeService.scannedProduct;

                              if (scannedProduct == null) return;

                              // Afficher un indicateur de chargement
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ajout en cours...'),
                                  duration: Duration(milliseconds: 500),
                                ),
                              );

                              // Créer un objet Product temporaire AVEC TOUS LES CHAMPS REQUIS
                              final productToAdd = Product(
                                id: scannedProduct.id,
                                name: scannedProduct.name,
                                description: scannedProduct.description,
                                listPrice: _selectedOffer!.price,
                                packaging: scannedProduct.packaging,
                                isPromotion: _selectedOffer!.isPromotion,
                                promotionPrice: _selectedOffer!.originalPrice,
                                promotionStart: null,
                                promotionEnd: null,
                                popularRank: 0,
                                defaultCode: null,
                                barcode: scannedProduct.barcode,
                                categoryId: null,
                                categoryName: null,
                                supplierId: _selectedOffer!.supplierId,
                                supplierName: _selectedOffer!.supplierName,
                                volume: null,
                                weight: null,
                                active: true,
                                imageUrl: scannedProduct.imageUrl,
                                stockQuantity: _selectedOffer!.stock,
                                minStockAlert: null,
                                maxStockAlert: null,
                              );

                              bool success = await cartService.addToCart(
                                productToAdd,
                                quantity: _quantity,
                              );

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${_quantity} x ${scannedProduct.name} ajouté au panier'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(cartService.error ?? 'Erreur lors de l\'ajout au panier'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Ajouter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(ProductOffer offer, bool isSelected, AppLocalizations localizations) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOffer = offer;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar fournisseur
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  offer.supplierName[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Infos fournisseur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.supplierName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Livraison: ${offer.deliveryDays} jours',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        offer.isInStock ? 'En stock' : 'Rupture',
                        style: TextStyle(
                          fontSize: 11,
                          color: offer.isInStock ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Prix
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (offer.isPromotion)
                  Text(
                    '${offer.originalPrice?.toStringAsFixed(2)} ${localizations.currency}',
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                Text(
                  '${offer.price.toStringAsFixed(2)} ${localizations.currency}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : Color(0xFF2D3A4F),
                  ),
                ),
                if (offer.isPromotion)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '-${offer.discountPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            // Radio bouton
            if (!isSelected)
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
            if (isSelected)
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}