// lib/models/order.dart
import 'order_item.dart';
import 'package:flutter/material.dart';

class Order {
  final int id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final double subtotal;
  final double tax;
  final double shippingCost;
  final double total;
  final String? shippingAddress;
  final String? shippingCity;
  final String? shippingZip;
  final String? shippingPhone;
  final String? notes;
  final String? paymentMethod;
  final DateTime createdAt;
  final List<OrderItem>? items;

  // Données du client
  final int? customerId;
  final String? customerName;
  final String? customerCompanyName;
  final String? customerEmail;
  final String? customerPhone;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.subtotal,
    required this.tax,
    required this.shippingCost,
    required this.total,
    this.shippingAddress,
    this.shippingCity,
    this.shippingZip,
    this.shippingPhone,
    this.notes,
    this.paymentMethod,
    required this.createdAt,
    this.items,
    this.customerId,
    this.customerName,
    this.customerCompanyName,
    this.customerEmail,
    this.customerPhone,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Extraire les données du client
    Map<String, dynamic>? customerData = json['customer'];

    return Order(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String,
      status: json['status'] as String,
      paymentStatus: json['payment_status'] as String,
      subtotal: _toDouble(json['subtotal']),
      tax: _toDouble(json['tax']),
      shippingCost: _toDouble(json['shipping_cost']),
      total: _toDouble(json['total']),
      shippingAddress: json['shipping_address'] as String?,
      shippingCity: json['shipping_city'] as String?,
      shippingZip: json['shipping_zip'] as String?,
      shippingPhone: json['shipping_phone'] as String?,
      notes: json['notes'] as String?,
      paymentMethod: json['payment_method'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: json['items'] != null
          ? (json['items'] as List)
          .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
          .toList()
          : null,
      customerId: customerData?['id'] as int?,
      customerName: customerData?['name'] as String?,
      customerCompanyName: customerData?['company_name'] as String?,
      customerEmail: customerData?['email'] as String?,
      customerPhone: customerData?['phone'] as String?,
    );
  }

  // Fonction utilitaire pour convertir en double en toute sécurité
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
      case 'unpaid': return 'Impayée';
      case 'paid': return 'Payée';
      default: return paymentStatus;
    }
  }

  Color get paymentStatusColor {
    switch (paymentStatus) {
      case 'unpaid': return Colors.red;
      case 'paid': return Colors.green;
      default: return Colors.grey;
    }
  }

  bool get isPaid => paymentStatus == 'paid';
  double get amountTotal => total;
  String? get supplierName => null;

  // Nom du client à afficher
  String get customerDisplayName {
    if (customerCompanyName != null && customerCompanyName!.isNotEmpty) {
      return customerCompanyName!;
    }
    if (customerName != null && customerName!.isNotEmpty) {
      return customerName!;
    }
    return 'Client #$id';
  }
}