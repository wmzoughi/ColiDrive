// lib/screens/commercant/product_detail_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../models/product.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../services/review_service.dart';
import '../../utils/constants.dart';
import '../../widgets/product_image.dart';
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
  ProductPackaging? _selectedPackaging;
  bool _isLoadingPackagings = false;
  List<ProductPackaging> _packagings = [];

  @override
  void initState() {
    super.initState();
    _loadPackagings();
  }

  // 👇 CHARGER LES CONDITIONNEMENTS AVEC LA ROUTE PUBLIQUE
  Future<void> _loadPackagings() async {
    setState(() => _isLoadingPackagings = true);

    try {
      // 👉 UTILISER LA ROUTE PUBLIQUE (SANS TOKEN)
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/products/${widget.product.id}/packagings'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Chargement conditionnements - Status: ${response.statusCode}');
      print('📥 Réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List packagingsJson = data['data']['packagings'] ?? [];
          final packagings = packagingsJson.map((p) => ProductPackaging.fromJson(p)).toList();

          print('📦 Conditionnements trouvés: ${packagings.length}');
          for (var p in packagings) {
            print('   - ${p.name}: ${p.quantity} pièces, prix: ${p.price}');
          }

          setState(() {
            _packagings = packagings;
            // Sélectionner le conditionnement par défaut s'il existe
            if (_packagings.isNotEmpty) {
              final defaultPackaging = _packagings.firstWhere(
                    (p) => p.isDefault,
                orElse: () => _packagings.first,
              );
              _selectedPackaging = defaultPackaging;
            }
          });
        }
      } else {
        print('❌ Erreur: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur chargement conditionnements: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPackagings = false);
      }
    }
  }

  // Obtenir le prix pour le conditionnement sélectionné
  double get _currentPrice {
    if (_selectedPackaging != null && _selectedPackaging!.price != null) {
      return _selectedPackaging!.price!;
    }
    return widget.product.currentPrice;
  }

  // Obtenir la quantité totale en pièces
  int get _totalPiecesQuantity {
    if (_selectedPackaging != null) {
      return _quantity * _selectedPackaging!.quantity;
    }
    return _quantity;
  }

  // Obtenir le texte du conditionnement
  String _getPackagingDisplayText(ProductPackaging packaging) {
    if (packaging.price != null) {
      return '${packaging.name} (${packaging.quantity} pièces) - ${packaging.price!.toStringAsFixed(2)} MAD';
    }
    return '${packaging.name} (${packaging.quantity} pièces)';
  }

  // Fonction pour obtenir le statut du stock (adapté au conditionnement)
  Map<String, dynamic> _getStockStatus() {
    int stock = widget.product.stockQuantity ?? 0;
    int requiredQuantity = _totalPiecesQuantity;
    int minAlert = widget.product.minStockAlert ?? 5;

    if (stock <= 0) {
      return {
        'color': Colors.red,
        'icon': Icons.error,
        'label': 'Rupture de stock',
        'message': 'Produit indisponible',
        'available': false
      };
    } else if (stock < requiredQuantity) {
      return {
        'color': Colors.red,
        'icon': Icons.error,
        'label': 'Stock insuffisant',
        'message': 'Stock disponible: $stock pièces',
        'available': false
      };
    } else if (stock <= minAlert) {
      return {
        'color': Colors.orange,
        'icon': Icons.warning,
        'label': 'Stock faible',
        'message': 'Plus que $stock pièces en stock',
        'available': true
      };
    } else {
      return {
        'color': Colors.green,
        'icon': Icons.check_circle,
        'label': 'En stock',
        'message': '$stock pièces disponibles',
        'available': true
      };
    }
  }

  // Fonction pour obtenir la note du fournisseur
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

    // Obtenir le statut du stock
    final stockStatus = _getStockStatus();

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
                              if (product.isInPromotion && _selectedPackaging == null)
                                Text(
                                  '${product.listPrice.toStringAsFixed(2)} ${localizations.currency}',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              Text(
                                '${_currentPrice.toStringAsFixed(2)} ${localizations.currency}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: product.isInPromotion && _selectedPackaging == null
                                      ? Colors.red
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 👇 SÉLECTEUR DE CONDITIONNEMENT
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.inventory_2, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Choisissez votre conditionnement',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_isLoadingPackagings)
                            const Center(child: CircularProgressIndicator())
                          else if (_packagings.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Aucun conditionnement disponible. Achat à l\'unité.',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // Option "Pièce unitaire"
                                FilterChip(
                                  label: Text('Pièce unitaire (1 pièce)'),
                                  selected: _selectedPackaging == null,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedPackaging = null;
                                        _quantity = 1;
                                      });
                                    }
                                  },
                                  selectedColor: AppColors.primary,
                                  labelStyle: TextStyle(
                                    color: _selectedPackaging == null ? Colors.white : Colors.grey.shade700,
                                  ),
                                ),
                                // Options de conditionnements
                                ..._packagings.map((packaging) {
                                  final isSelected = _selectedPackaging == packaging;
                                  return FilterChip(
                                    label: Text(_getPackagingDisplayText(packaging)),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedPackaging = packaging;
                                          _quantity = 1;
                                        });
                                      }
                                    },
                                    selectedColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey.shade700,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          if (_selectedPackaging != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '✨ Économisez en achetant par ${_selectedPackaging!.name.toLowerCase()} !',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Indicateur de stock
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

                    // Section avis du fournisseur (garder le reste du code inchangé...)
                    // ... le reste du code reste identique ...

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
                                      int maxQuantity = widget.product.stockQuantity ?? 0;
                                      if (_selectedPackaging != null) {
                                        maxQuantity = (widget.product.stockQuantity ?? 0) ~/ _selectedPackaging!.quantity;
                                      }
                                      if (stockStatus['available'] && _quantity < maxQuantity) {
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

                          const SizedBox(height: 8),

                          // Information sur la quantité totale en pièces
                          if (_selectedPackaging != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Soit $_totalPiecesQuantity pièces au total',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),

                          const SizedBox(height: 8),

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
                                '${(_currentPrice * _quantity).toStringAsFixed(2)} ${localizations.currency}',
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

                                final cartItem = {
                                  'product': widget.product,
                                  'quantity': _quantity,
                                  'packaging': _selectedPackaging,
                                  'total_pieces': _totalPiecesQuantity,
                                  'unit_price': _currentPrice,
                                };

                                bool success = await cartService.addToCartWithPackaging(cartItem);

                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(localizations.addToCart),
                                      backgroundColor: AppColors.success,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  Navigator.pop(context);
                                } else if (mounted) {
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
                                  : null,
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

                          // Message si stock faible
                          if (stockStatus['available'] &&
                              widget.product.stockQuantity != null &&
                              widget.product.stockQuantity! < 10)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '⚠️ Plus que ${widget.product.stockQuantity} pièces en stock',
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