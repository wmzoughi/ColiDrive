// lib/models/product.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'product_image.dart';
import '../utils/constants.dart';

class ProductPackaging {
  final int? id;
  final String name;
  final String type;
  final int quantity;
  final double? price;
  final double? weight;
  final double? volume;
  final String? barcode;
  final bool isDefault;
  final int sortOrder;

  ProductPackaging({
    this.id,
    required this.name,
    required this.type,
    required this.quantity,
    this.price,
    this.weight,
    this.volume,
    this.barcode,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  factory ProductPackaging.fromJson(Map<String, dynamic> json) {
    return ProductPackaging(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      quantity: json['quantity'],
      price: json['price'] != null ? _toDouble(json['price']) : null,
      weight: json['weight'] != null ? _toDouble(json['weight']) : null,
      volume: json['volume'] != null ? _toDouble(json['volume']) : null,
      barcode: json['barcode'],
      isDefault: json['is_default'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String get displayName => '$name (${quantity} pièces)';
  String get formattedPrice => price != null ? '${price!.toStringAsFixed(2)} MAD' : 'Prix sur demande';
}

class Product {
  final int id;
  final String name;
  final String? description;
  final double listPrice;
  final String? packaging;
  final bool isPromotion;
  final double? promotionPrice;
  final DateTime? promotionStart;
  final DateTime? promotionEnd;
  final int? popularRank;
  final String? defaultCode;
  final String? barcode;
  final int? categoryId;
  final String? categoryName;
  final int supplierId;
  final String? supplierName;
  final double? volume;
  final double? weight;
  final bool active;
  final String? imageUrl;
  final int? stockQuantity;
  final int? minStockAlert;
  final int? maxStockAlert;
  final List<ProductPackaging>? packagings;
  final String? baseUnit;
  final int? defaultPackagingQuantity;
  final double? unitWeight;
  final double? unitVolume;

  // 👇 NOUVEAU CHAMP POUR LES IMAGES MULTIPLES
  final List<ProductImage>? images;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.listPrice,
    this.packaging,
    required this.isPromotion,
    this.promotionPrice,
    this.promotionStart,
    this.promotionEnd,
    this.popularRank,
    this.defaultCode,
    this.barcode,
    this.categoryId,
    this.categoryName,
    required this.supplierId,
    this.supplierName,
    this.volume,
    this.weight,
    required this.active,
    this.imageUrl,
    this.stockQuantity,
    this.minStockAlert,
    this.maxStockAlert,
    this.packagings,
    this.baseUnit,
    this.defaultPackagingQuantity,
    this.unitWeight,
    this.unitVolume,
    this.images,
  });

  // ==================== ACCESSEURS POUR LES IMAGES ====================

  ProductImage? get primaryImage {
    if (images == null || images!.isEmpty) return null;
    return images!.firstWhere(
          (img) => img.isPrimary,
      orElse: () => images!.first,
    );
  }

  String? get mainImageUrl {
    if (primaryImage != null) return primaryImage!.fullUrl;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      final baseUrl = AppConstants.baseUrl.replaceFirst('/api', '');
      if (imageUrl!.startsWith('http')) return imageUrl;
      if (imageUrl!.startsWith('/storage/')) return '$baseUrl$imageUrl';
      return '$baseUrl/$imageUrl';
    }
    return null;
  }

  // 👉 CE GETTER EST ESSENTIEL - IL RÉSOUT VOTRE ERREUR
  List<String> get allImageUrls {
    if (images != null && images!.isNotEmpty) {
      return images!.map((img) => img.fullUrl).toList();
    }
    if (mainImageUrl != null) return [mainImageUrl!];
    return [];
  }

  List<Map<String, dynamic>> get formattedImages {
    if (images != null && images!.isNotEmpty) {
      return images!.map((img) => {
        'id': img.id,
        'url': img.fullUrl,
        'is_primary': img.isPrimary,
        'sort_order': img.sortOrder,
      }).toList();
    }
    return [];
  }

  bool get hasImages => allImageUrls.isNotEmpty;
  int get imageCount => allImageUrls.length;

  // ==================== ACCESSEURS PRIX ====================

  double get currentPrice {
    final now = DateTime.now();
    if (isPromotion &&
        promotionStart != null &&
        promotionEnd != null &&
        promotionStart!.isBefore(now) &&
        promotionEnd!.isAfter(now)) {
      return promotionPrice ?? listPrice;
    }
    return listPrice;
  }

  bool get isInPromotion {
    final now = DateTime.now();
    return isPromotion &&
        promotionStart != null &&
        promotionEnd != null &&
        promotionStart!.isBefore(now) &&
        promotionEnd!.isAfter(now);
  }

  int get discountPercentage {
    if (!isInPromotion || promotionPrice == null || promotionPrice! >= listPrice) {
      return 0;
    }
    double discount = ((listPrice - promotionPrice!) / listPrice * 100).roundToDouble();
    return discount.toInt();
  }

  double? get oldPrice {
    return isInPromotion ? listPrice : null;
  }

  // ==================== ACCESSEURS STOCK ====================

  bool get isInStock {
    if (stockQuantity == null) return true;
    return stockQuantity! > 0;
  }

  bool get isLowStock {
    if (stockQuantity == null) return false;
    return stockQuantity! > 0 && stockQuantity! <= (minStockAlert ?? 5);
  }

  String get stockStatus {
    if (stockQuantity == null) return 'Inconnu';
    if (stockQuantity! <= 0) return 'Rupture';
    if (stockQuantity! <= (minStockAlert ?? 5)) return 'Stock faible';
    return 'En stock';
  }

  Color get stockStatusColor {
    if (stockQuantity == null) return Colors.grey;
    if (stockQuantity! <= 0) return Colors.red;
    if (stockQuantity! <= (minStockAlert ?? 5)) return Colors.orange;
    return Colors.green;
  }

  IconData get stockStatusIcon {
    if (stockQuantity == null) return Icons.help_outline;
    if (stockQuantity! <= 0) return Icons.error;
    if (stockQuantity! <= (minStockAlert ?? 5)) return Icons.warning;
    return Icons.check_circle;
  }

  // ==================== FACTORY FROMJSON ====================

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

  static String _extractText(dynamic field) {
    if (field == null) return '';
    if (field is String) {
      if (field.startsWith('{')) {
        try {
          final Map<String, dynamic> parsed = jsonDecode(field);
          return parsed['en_US'] ?? parsed['fr_FR'] ?? parsed['ar_MA'] ?? field;
        } catch (e) {
          return field;
        }
      }
      return field;
    }
    if (field is Map) {
      return field['en_US'] ?? field['fr_FR'] ?? field['ar_MA'] ?? '';
    }
    return '';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Extraire les conditionnements
    List<ProductPackaging>? packagings;
    if (json['packagings'] != null) {
      packagings = (json['packagings'] as List)
          .map((p) => ProductPackaging.fromJson(p))
          .toList();
    }

    // 👇 EXTRAIRE LES IMAGES
    List<ProductImage>? images;
    if (json['images'] != null) {
      images = (json['images'] as List)
          .map((img) => ProductImage.fromJson(img))
          .toList();
    }

    return Product(
      id: json['id'],
      name: _extractText(json['name']),
      description: _extractText(json['description']),
      listPrice: _toDouble(json['list_price']),
      packaging: json['packaging'],
      isPromotion: json['is_promotion'] ?? false,
      promotionPrice: json['promotion_price'] != null ? _toDouble(json['promotion_price']) : null,
      promotionStart: json['promotion_start'] != null ? DateTime.tryParse(json['promotion_start']) : null,
      promotionEnd: json['promotion_end'] != null ? DateTime.tryParse(json['promotion_end']) : null,
      popularRank: json['popular_rank'],
      defaultCode: json['default_code'],
      barcode: json['barcode'],
      categoryId: json['categ_id'],
      categoryName: json['category']?['name'],
      supplierId: _toInt(json['supplier_id']),
      supplierName: json['supplier']?['name'],
      volume: json['volume'] != null ? _toDouble(json['volume']) : null,
      weight: json['weight'] != null ? _toDouble(json['weight']) : null,
      active: json['active'] ?? true,
      imageUrl: json['image_url'],
      stockQuantity: _toInt(json['stock_quantity']),
      minStockAlert: _toInt(json['min_stock_alert']),
      maxStockAlert: _toInt(json['max_stock_alert']),
      packagings: packagings,
      baseUnit: json['base_unit'],
      defaultPackagingQuantity: json['default_packaging_quantity'],
      unitWeight: json['unit_weight'] != null ? _toDouble(json['unit_weight']) : null,
      unitVolume: json['unit_volume'] != null ? _toDouble(json['unit_volume']) : null,
      images: images,
    );
  }
}