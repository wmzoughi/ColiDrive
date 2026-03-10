// lib/models/cart_item.dart
import 'product.dart';

class CartItem {
  final int id;
  final Product product;
  int quantity;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
    );
  }

  double get totalPrice => product.currentPrice * quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': product.id,
      'product_name': product.name,
      'quantity': quantity,
      'price': product.currentPrice,
      'total': totalPrice,
    };
  }
}