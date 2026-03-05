import 'package:flutter/material.dart';

class Order {
  final int id;
  final String orderNumber;
  final double amountTotal;
  final String status;
  final String paymentStatus;
  final DateTime createdAt;
  final String? customerName;
  final List<OrderItem>? items;
  final Map<String, dynamic>? supplier; // Info du fournisseur

  Order({
    required this.id,
    required this.orderNumber,
    required this.amountTotal,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    this.customerName,
    this.items,
    this.supplier,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Traitement des items si présents
    List<OrderItem>? itemsList;
    if (json['order_line'] != null || json['lines'] != null) {
      final lines = json['order_line'] ?? json['lines'] ?? [];
      itemsList = (lines as List).map((item) => OrderItem.fromJson(item)).toList();
    }

    return Order(
      id: json['id'],
      orderNumber: json['order_number'] ?? json['name'] ?? '#${json['id']}',
      amountTotal: (json['amount_total'] ?? 0).toDouble(),
      status: json['delivery_status'] ?? json['state'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'unpaid',
      createdAt: json['create_date'] != null
          ? DateTime.parse(json['create_date'])
          : DateTime.now(),
      customerName: json['partner_id']?['name'] ?? json['partner']?['name'],
      items: itemsList,
      supplier: json['supplier_id'] is Map ? json['supplier_id'] : null,
    );
  }

  // Helpers
  bool get isPaid => paymentStatus == 'paid' || paymentStatus == 'Payé';
  bool get isPending => status == 'pending' || status == 'En attente';
  bool get isDelivered => status == 'delivered' || status == 'Livrée';

  String get statusLabel {
    switch (status) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmée';
      case 'preparing': return 'En préparation';
      case 'delivering': return 'En livraison';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      default: return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'preparing': return Colors.purple;
      case 'delivering': return Colors.indigo;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String get paymentStatusLabel {
    switch (paymentStatus) {
      case 'paid': return 'Payée';
      case 'unpaid': return 'Impayée';
      case 'partial': return 'Partielle';
      default: return paymentStatus;
    }
  }

  Color get paymentStatusColor {
    switch (paymentStatus) {
      case 'paid': return Colors.green;
      case 'unpaid': return Colors.red;
      case 'partial': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String? get supplierName {
    if (supplier != null) {
      return supplier!['name'] ?? supplier!['company_name'] ?? 'Fournisseur';
    }
    return 'Fournisseur';
  }
}

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;
  final String? packaging;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.packaging,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? json['name'] ?? 'Produit',
      quantity: json['product_uom_qty']?.toInt() ?? json['quantity'] ?? 1,
      price: (json['price_unit'] ?? 0).toDouble(),
      subtotal: (json['price_subtotal'] ?? 0).toDouble(),
      packaging: json['packaging'],
    );
  }
}