// lib/models/cart_item.dart
import 'product.dart';

class CartItem {
  final int id;
  final Product product;
  int quantity;

  final int? packagingId;
  final String? packagingName;
  final int? packagingQuantity;
  final int? totalPieces;
  final double? unitPrice;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.packagingId,
    this.packagingName,
    this.packagingQuantity,
    this.totalPieces,
    this.unitPrice,
  });

  double get effectivePrice {
    if (unitPrice != null) {
      return unitPrice!;
    }
    return product.currentPrice;
  }

  double get totalPrice => effectivePrice * quantity;

  String get packagingDisplay {
    if (packagingName != null && packagingName!.isNotEmpty) {
      return '${packagingName}s (${packagingQuantity ?? 1} pièces)';
    }
    return 'Pièce unitaire';
  }

  String get quantityDisplay {
    if (packagingName != null && packagingName!.isNotEmpty) {
      final totalPiecesValue = totalPieces ?? (quantity * (packagingQuantity ?? 1));
      return '$quantity $packagingName(s) ($totalPiecesValue pièces)';
    }
    return '$quantity pièce(s)';
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // 👈 UTILISER price_at_time COMME PRIX UNITAIRE
    double price = json['price_at_time'] is int
        ? (json['price_at_time'] as int).toDouble()
        : (json['price_at_time'] as double);

    return CartItem(
      id: json['id'],
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
      packagingId: json['packaging_id'],
      packagingName: json['packaging_name'],
      packagingQuantity: json['packaging_quantity'],
      totalPieces: json['total_pieces'],
      unitPrice: price,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': product.id,
      'product_name': product.name,
      'quantity': quantity,
      'packaging_id': packagingId,
      'packaging_name': packagingName,
      'packaging_quantity': packagingQuantity,
      'total_pieces': totalPieces,
      'unit_price': unitPrice,
      'price': effectivePrice,
      'total': totalPrice,
    };
  }
}