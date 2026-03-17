// lib/services/notification_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/notification.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class NotificationService extends ChangeNotifier {
  final AuthService _authService;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  NotificationService(this._authService);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authService.token != null) 'Authorization': 'Bearer ${_authService.token}',
  };

  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Charger les notifications avec filtre selon le type d'utilisateur
  // lib/services/notification_service.dart

  Future<bool> loadNotifications({bool reset = false}) async {
    if (reset) {
      _notifications = [];
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return false;

    _isLoading = true;
    _safeNotify();

    try {
      String url = '${AppConstants.baseUrl}/notifications?page=$_currentPage';

      print('📥 Chargement des notifications - Page: $_currentPage');
      print('📥 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      print('📥 Statut: ${response.statusCode}');
      print('📥 Réponse: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final responseData = NotificationResponse.fromJson(data['data']);

        // ✅ AJOUTER TOUTES LES NOTIFICATIONS SANS FILTRER
        _notifications.addAll(responseData.notifications);

        // ✅ METTRE À JOUR LE COMPTEUR GLOBAL
        _unreadCount = responseData.unreadCount;

        _currentPage++;
        _hasMore = _currentPage <= responseData.pagination.lastPage;

        print('✅ ${_notifications.length} notifications chargées');
        print('✅ Non lues: $_unreadCount');

        _isLoading = false;
        _safeNotify();
        return true;
      } else {
        _error = data['message'] ?? 'Erreur';
        _isLoading = false;
        _safeNotify();
        return false;
      }
    } catch (e) {
      print('❌ Erreur: $e');
      _error = 'Erreur réseau: ${e.toString()}';
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  // Obtenir les notifications pour fournisseur
  List<AppNotification> getSupplierNotifications() {
    return _notifications.where((n) =>
    n.type == 'new_order' || n.type == 'order_cancelled'
    ).toList();
  }

  // Obtenir les notifications pour commerçant
  List<AppNotification> getMerchantNotifications() {
    return _notifications.where((n) =>
    n.type == 'order_confirmed' ||
        n.type == 'order_shipped' ||
        n.type == 'order_delivered' ||
        n.type == 'order_cancelled'
    ).toList();
  }

  // Marquer une notification comme lue
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/notifications/$notificationId/read'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await loadNotifications(reset: true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Marquer toutes les notifications comme lues
  Future<bool> markAllAsRead() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/notifications/read-all'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await loadNotifications(reset: true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Supprimer une notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/notifications/$notificationId'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _notifications.removeWhere((n) => n.id == notificationId);
        _updateUnreadCount();
        _safeNotify();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Supprimer toutes les notifications
  Future<bool> deleteAllNotifications() async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/notifications'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _notifications.clear();
        _unreadCount = 0;
        _safeNotify();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Rafraîchir les notifications
  Future<void> refresh() async {
    await loadNotifications(reset: true);
  }

  // Mettre à jour le compteur de non lues
  void _updateUnreadCount() {
    final userType = _authService.currentUser?.userType;

    if (userType == 'fournisseur') {
      _unreadCount = _notifications.where((n) =>
      !n.isRead && (n.type == 'new_order' || n.type == 'order_cancelled')
      ).length;
    } else if (userType == 'commercant') {
      _unreadCount = _notifications.where((n) =>
      !n.isRead && (n.type == 'order_confirmed' ||
          n.type == 'order_shipped' ||
          n.type == 'order_delivered' ||
          n.type == 'order_cancelled')
      ).length;
    } else {
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    }
  }
}