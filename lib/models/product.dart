// lib/models/product.dart
import 'dart:convert';
import 'package:flutter/material.dart';

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
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Fonction pour extraire le texte du JSONB
    String _extractText(dynamic field) {
      if (field == null) return '';

      // Si c'est déjà une String
      if (field is String) {
        // Vérifier si c'est du JSON (commence par {)
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

      // Si c'est un Map
      if (field is Map) {
        return field['en_US'] ?? field['fr_FR'] ?? field['ar_MA'] ?? '';
      }

      return '';
    }

    return Product(
      id: json['id'],
      name: _extractText(json['name']),
      description: _extractText(json['description']),
      listPrice: (json['list_price'] ?? 0).toDouble(),
      packaging: json['packaging'],
      isPromotion: json['is_promotion'] ?? false,
      promotionPrice: json['promotion_price']?.toDouble(),
      promotionStart: json['promotion_start'] != null
          ? DateTime.parse(json['promotion_start'])
          : null,
      promotionEnd: json['promotion_end'] != null
          ? DateTime.parse(json['promotion_end'])
          : null,
      popularRank: json['popular_rank'],
      defaultCode: json['default_code'],
      categoryId: json['categ_id'],
      categoryName: json['category']?['name'],
      supplierId: json['supplier_id'] ?? 0,
      supplierName: json['supplier']?['name'],
      volume: json['volume']?.toDouble(),
      weight: json['weight']?.toDouble(),
      active: json['active'] ?? true,
      imageUrl: json['image_url'],
      stockQuantity: json['stock_quantity'] ?? 0,
      minStockAlert: json['min_stock_alert'] ?? 5,
      maxStockAlert: json['max_stock_alert'] ?? 100,
    );
  }

  // Prix actuel (avec promotion si applicable)
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

  // Vérifier si le produit est en promotion
  bool get isInPromotion {
    final now = DateTime.now();
    return isPromotion &&
        promotionStart != null &&
        promotionEnd != null &&
        promotionStart!.isBefore(now) &&
        promotionEnd!.isAfter(now);
  }

  // 👇 AJOUTEZ CETTE PROPRIÉTÉ
  // Pourcentage de réduction
  int get discountPercentage {
    if (!isInPromotion || promotionPrice == null || promotionPrice! >= listPrice) {
      return 0;
    }
    double discount = ((listPrice - promotionPrice!) / listPrice * 100).roundToDouble();
    return discount.toInt();
  }

  // Ancien prix (pour affichage barré)
  double? get oldPrice {
    return isInPromotion ? listPrice : null;
  }

  // Vérifier si le produit est en stock
  bool get isInStock {
    if (stockQuantity == null) return true;
    return stockQuantity! > 0;
  }

  // Vérifier si le stock est faible
  bool get isLowStock {
    if (stockQuantity == null) return false;
    return stockQuantity! > 0 && stockQuantity! <= (minStockAlert ?? 5);
  }

  // Statut du stock en texte
  String get stockStatus {
    if (stockQuantity == null) return 'Inconnu';
    if (stockQuantity! <= 0) return 'Rupture';
    if (stockQuantity! <= (minStockAlert ?? 5)) return 'Stock faible';
    return 'En stock';
  }

  // Couleur du statut de stock
  Color get stockStatusColor {
    if (stockQuantity == null) return Colors.grey;
    if (stockQuantity! <= 0) return Colors.red;
    if (stockQuantity! <= (minStockAlert ?? 5)) return Colors.orange;
    return Colors.green;
  }

  // Icône du statut de stock
  IconData get stockStatusIcon {
    if (stockQuantity == null) return Icons.help_outline;
    if (stockQuantity! <= 0) return Icons.error;
    if (stockQuantity! <= (minStockAlert ?? 5)) return Icons.warning;
    return Icons.check_circle;
  }
}