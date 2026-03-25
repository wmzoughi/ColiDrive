// lib/models/product_offer.dart

class ProductOffer {
  final int productId;
  final int supplierId;
  final String supplierName;
  final double price;
  final double? originalPrice;
  final bool isPromotion;
  final int stock;
  final String? packaging;
  final String? imageUrl;
  final int deliveryDays;

  ProductOffer({
    required this.productId,
    required this.supplierId,
    required this.supplierName,
    required this.price,
    this.originalPrice,
    required this.isPromotion,
    required this.stock,
    this.packaging,
    this.imageUrl,
    required this.deliveryDays,
  });

  // ✅ FONCTIONS UTILITAIRES À L'INTÉRIEUR DE LA CLASSE
  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        String cleaned = value.trim().replaceAll(',', '.');
        return double.parse(cleaned);
      } catch (e) {
        print('❌ Erreur parsing prix: $value -> $e');
        return 0.0;
      }
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
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

  factory ProductOffer.fromJson(Map<String, dynamic> json) {
    print('🔍 DEBUG ProductOffer.fromJson:');
    print('   price reçu: ${json['price']} (type: ${json['price'].runtimeType})');
    print('   original_price reçu: ${json['original_price']}');

    double parsedPrice = _parsePrice(json['price']);
    print('   price parsé: $parsedPrice');

    return ProductOffer(
      productId: _parseInt(json['product_id']),
      supplierId: _parseInt(json['supplier_id']),
      supplierName: json['supplier_name'] ?? '',
      price: parsedPrice,
      originalPrice: json['original_price'] != null ? _parsePrice(json['original_price']) : null,
      isPromotion: json['is_promotion'] ?? false,
      stock: _parseInt(json['stock']),
      packaging: json['packaging'],
      imageUrl: json['image_url'],
      deliveryDays: _parseInt(json['delivery_days'] ?? 5),
    );
  }

  // ✅ POURCENTAGE DE RÉDUCTION
  double get discountPercent {
    if (!isPromotion || originalPrice == null) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  // ✅ VÉRIFIER SI LE PRODUIT EST EN STOCK
  bool get isInStock => stock > 0;

  // ✅ PRIX FORMATÉ
  String get formattedPrice {
    return '${price.toStringAsFixed(2)} MAD';
  }

  // ✅ PRIX ORIGINAL FORMATÉ
  String? get formattedOriginalPrice {
    if (originalPrice == null) return null;
    return '${originalPrice!.toStringAsFixed(2)} MAD';
  }
}

class ScannedProduct {
  final int id;
  final String name;
  final String barcode;
  final String? packaging;
  final String? imageUrl;
  final String? description;
  final ProductOffer currentSupplier;
  final List<ProductOffer> otherOffers;

  ScannedProduct({
    required this.id,
    required this.name,
    required this.barcode,
    this.packaging,
    this.imageUrl,
    this.description,
    required this.currentSupplier,
    required this.otherOffers,
  });

  // ✅ FONCTIONS UTILITAIRES À L'INTÉRIEUR DE LA CLASSE
  static int _toInt(dynamic value) {
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

  static double _toDouble(dynamic value) {
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

  factory ScannedProduct.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final current = json['current_supplier'] ?? {};
    final offers = json['other_offers'] as List? ?? [];

    return ScannedProduct(
      id: _toInt(product['id']),
      name: product['name'] ?? '',
      barcode: product['barcode'] ?? '',
      packaging: product['packaging'],
      imageUrl: product['image_url'],
      description: product['description'],
      currentSupplier: ProductOffer(
        productId: _toInt(product['id']),
        supplierId: _toInt(current['id']),
        supplierName: current['name'] ?? '',
        price: _toDouble(current['price']),
        originalPrice: current['original_price'] != null ? _toDouble(current['original_price']) : null,
        isPromotion: current['is_promotion'] ?? false,
        stock: _toInt(current['stock']),
        packaging: product['packaging'],
        imageUrl: product['image_url'],
        deliveryDays: 5,
      ),
      otherOffers: offers.map((o) => ProductOffer.fromJson(o)).toList(),
    );
  }

  // ✅ OBTENIR TOUTES LES OFFRES (TRIÉES PAR PRIX CROISSANT)
  List<ProductOffer> getAllOffers() {
    final offers = [currentSupplier, ...otherOffers]
        .where((o) => o.isInStock)
        .toList();
    offers.sort((a, b) => a.price.compareTo(b.price));
    return offers;
  }

  // ✅ OBTENIR LA MEILLEURE OFFRE (PRIX LE PLUS BAS)
  ProductOffer? get bestOffer {
    final offers = getAllOffers();
    return offers.isEmpty ? null : offers.first;
  }

  // ✅ OBTENIR LA LISTE DES FOURNISSEURS
  List<String> get supplierNames {
    return getAllOffers().map((o) => o.supplierName).toList();
  }

  // ✅ OBTENIR LA FOURCHETTE DE PRIX
  String get priceRange {
    final offers = getAllOffers();
    if (offers.isEmpty) return 'Non disponible';
    if (offers.length == 1) return offers.first.formattedPrice;
    return '${offers.first.formattedPrice} - ${offers.last.formattedPrice}';
  }
}