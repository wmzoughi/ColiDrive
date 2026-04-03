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
  int get unreadCount => _unreadCount;  // ✅ Déjà correct
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  NotificationService(this._authService) {
    // ✅ AJOUTER UN ÉCOUTEUR POUR RECHARGER QUAND L'UTILISATEUR CHANGE
    _authService.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (_authService.isAuthenticated) {
      refresh();
    } else {
      _notifications.clear();
      _unreadCount = 0;
      _safeNotify();
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authService.token != null) 'Authorization': 'Bearer ${_authService.token}',
  };

  void _safeNotify() {
    if (WidgetsBinding.instance != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  // ✅ AJOUTER UNE MÉTHODE POUR RECHARGER UNIQUEMENT LE COMPTEUR
  Future<int> refreshUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/notifications/unread-count'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _unreadCount = data['data']['unread_count'] ?? 0;
        _safeNotify();
        return _unreadCount;
      }
    } catch (e) {
      print('❌ Erreur refresh compteur: $e');
    }
    return _unreadCount;
  }

  // Charger les notifications avec filtre selon le type d'utilisateur
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

        _notifications.addAll(responseData.notifications);
        _unreadCount = responseData.unreadCount;  // ✅ MIS À JOUR

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

  // ✅ CORRECTION: Marquer une notification comme lue
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/notifications/$notificationId/read'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        // Mettre à jour localement
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          // Créer une nouvelle instance avec readAt
          final old = _notifications[index];
          _notifications[index] = AppNotification(
            id: old.id,
            type: old.type,
            data: old.data,
            readAt: DateTime.now(),
            createdAt: old.createdAt,
            createdAtRaw: old.createdAtRaw,
          );
          _unreadCount--;
          _safeNotify();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur markAsRead: $e');
      return false;
    }
  }

  // ✅ CORRECTION: Marquer toutes comme lues
  Future<bool> markAllAsRead() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/notifications/read-all'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        // Mettre à jour localement
        for (int i = 0; i < _notifications.length; i++) {
          final old = _notifications[i];
          if (old.readAt == null) {
            _notifications[i] = AppNotification(
              id: old.id,
              type: old.type,
              data: old.data,
              readAt: DateTime.now(),
              createdAt: old.createdAt,
              createdAtRaw: old.createdAtRaw,
            );
          }
        }
        _unreadCount = 0;
        _safeNotify();
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
        final wasUnread = _notifications.firstWhere((n) => n.id == notificationId).readAt == null;
        _notifications.removeWhere((n) => n.id == notificationId);
        if (wasUnread) {
          _unreadCount--;
        }
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

  void clearLocalNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    _isLoading = false;
    _safeNotify();
    print('✅ Notifications locales vidées');
  }

  // ✅ AJOUTER UNE MÉTHODE POUR ÉCOUTER LES NOTIFICATIONS EN TEMPS RÉEL
  void startListening() {
    // Vous pouvez implémenter un WebSocket ou un polling ici
    // Pour l'instant, on fait un polling simple toutes les 30 secondes
    Future.delayed(const Duration(seconds: 30), () {
      if (_authService.isAuthenticated) {
        refreshUnreadCount();
        startListening();
      }
    });
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}