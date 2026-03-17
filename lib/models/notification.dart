// lib/models/notification.dart

import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final String createdAt;
  final DateTime createdAtRaw;

  AppNotification({
    required this.id,
    required this.type,
    required this.data,
    this.readAt,
    required this.createdAt,
    required this.createdAtRaw,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      type: json['type'],
      data: json['data'] ?? {},
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: json['created_at'],
      createdAtRaw: DateTime.parse(json['created_at_raw']),
    );
  }

  bool get isRead => readAt != null;

  // ✅ Extraire le type depuis data ou depuis le type complet
  String get _shortType {
    // Si data contient un type, l'utiliser
    if (data.containsKey('type')) {
      return data['type'] as String;
    }
    // Sinon, extraire du nom de classe complet
    if (type.contains('\\')) {
      final parts = type.split('\\');
      final className = parts.last;

      // Convertir NewOrderNotification → new_order
      return className
          .replaceAll('Notification', '')
          .replaceAllMapped(
        RegExp(r'(?<=[a-z])([A-Z])'),
            (match) => '_${match[1]}',
      )
          .toLowerCase();
    }
    return 'unknown';
  }

  // Obtenir l'icône selon le type
  IconData get icon {
    switch (_shortType) {
      case 'new_order':
        return Icons.shopping_bag;
      case 'low_stock':
        return Icons.warning;
      case 'order_confirmed':
        return Icons.check_circle;
      case 'order_shipped':
        return Icons.local_shipping;
      case 'order_delivered':
        return Icons.check_circle;
      case 'order_cancelled':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  // Obtenir la couleur selon le type
  Color get color {
    switch (_shortType) {
      case 'new_order':
        return Colors.blue;
      case 'low_stock':
        return Colors.orange;
      case 'order_confirmed':
        return Colors.green;
      case 'order_shipped':
        return Colors.indigo;
      case 'order_delivered':
        return Colors.green;
      case 'order_cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Obtenir le message
  String get message {
    return data['message'] ?? 'Notification';
  }

  // Obtenir le titre
  String get title {
    switch (_shortType) {
      case 'new_order':
        return 'Nouvelle commande';
      case 'low_stock':
        return 'Stock faible';
      case 'order_confirmed':
        return 'Commande confirmée';
      case 'order_shipped':
        return 'Commande expédiée';
      case 'order_delivered':
        return 'Commande livrée';
      case 'order_cancelled':
        return 'Commande annulée';
      default:
        return 'Notification';
    }
  }

  // Action associée
  String? get actionRoute {
    if (data.containsKey('order_id')) {
      if (_shortType == 'new_order' || _shortType == 'order_cancelled') {
        return '/supplier/order-detail';
      } else {
        return '/merchant/order-detail';
      }
    }
    if (data.containsKey('product_id')) {
      return '/supplier/product-edit';
    }
    return null;
  }

  Map<String, dynamic> get actionArgs {
    if (data.containsKey('order_id')) {
      return {'order_id': data['order_id']};
    }
    if (data.containsKey('product_id')) {
      return {'product_id': data['product_id']};
    }
    return {};
  }
}

class NotificationResponse {
  final List<AppNotification> notifications;
  final int unreadCount;
  final PaginationInfo pagination;

  NotificationResponse({
    required this.notifications,
    required this.unreadCount,
    required this.pagination,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      notifications: (json['notifications'] as List)
          .map((n) => AppNotification.fromJson(n))
          .toList(),
      unreadCount: json['unread_count'] ?? 0,
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationInfo({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
    );
  }
}