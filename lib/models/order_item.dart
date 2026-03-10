// lib/models/order_item.dart
import 'dart:convert';

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final String? productSku;
  final double price;
  final int quantity;
  final double subtotal;
  final Map<String, dynamic>? productSnapshot;

  // Constructeur corrigé
  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSku,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.productSnapshot,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Gérer le cas où product_snapshot est une chaîne JSON
    Map<String, dynamic>? snapshot;

    if (json['product_snapshot'] != null) {
      if (json['product_snapshot'] is String) {
        try {
          snapshot = jsonDecode(json['product_snapshot'] as String);
        } catch (e) {
          print('❌ Erreur parsing product_snapshot: $e');
          snapshot = {};
        }
      } else if (json['product_snapshot'] is Map) {
        snapshot = Map<String, dynamic>.from(json['product_snapshot'] as Map);
      }
    }

    return OrderItem(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      productSku: json['product_sku'] as String?,
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      productSnapshot: snapshot,
    );
  }
}