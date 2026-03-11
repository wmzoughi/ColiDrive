// lib/services/dashboard_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/order.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import 'order_service.dart';  // 👈 AJOUTER CET IMPORT
import '../l10n/app_localizations.dart';

class DashboardService extends ChangeNotifier {
  // Statistiques
  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _confirmedOrders = 0;
  int _preparingOrders = 0;
  int _deliveringOrders = 0;
  int _deliveredOrders = 0;
  int _cancelledOrders = 0;
  double _totalSales = 0.0;
  int _outOfStockProducts = 0;

  // Transactions récentes
  List<Map<String, dynamic>> _recentTransactions = [];

  // Produits populaires
  List<Product> _popularProducts = [];

  // Graphique des ventes (données mensuelles)
  List<Map<String, dynamic>> _salesChartData = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  int get totalOrders => _totalOrders;
  int get pendingOrders => _pendingOrders;
  int get confirmedOrders => _confirmedOrders;
  int get preparingOrders => _preparingOrders;
  int get deliveringOrders => _deliveringOrders;
  int get deliveredOrders => _deliveredOrders;
  int get cancelledOrders => _cancelledOrders;
  double get totalSales => _totalSales;
  int get outOfStockProducts => _outOfStockProducts;
  List<Map<String, dynamic>> get recentTransactions => _recentTransactions;
  List<Product> get popularProducts => _popularProducts;
  List<Map<String, dynamic>> get salesChartData => _salesChartData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final AuthService _authService;

  DashboardService(this._authService);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer ${_authService.token}',
  };

  // Fonction utilitaire pour convertir n'importe quelle valeur en double
  double _toDouble(dynamic value) {
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

  // Fonction utilitaire pour convertir n'importe quelle valeur en int
  int _toInt(dynamic value) {
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

  // Formater en dirhams marocain
  String formatMAD(double amount, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} ${localizations.currency}';
  }

  Future<void> loadDashboardData() async {
    _setLoading(true);
    _clearError();

    try {
      // ✅ 1. Récupérer les STATISTIQUES depuis l'API
      final statsResponse = await http.get(
        Uri.parse('${AppConstants.baseUrl}/supplier/orders/stats'),
        headers: _headers,
      );

      // ✅ 2. Récupérer les commandes récentes
      final ordersResponse = await http.get(
        Uri.parse('${AppConstants.baseUrl}/supplier/orders?page=1&per_page=5'),
        headers: _headers,
      );

      // ✅ 3. Récupérer les produits
      final productsResponse = await http.get(
        Uri.parse('${AppConstants.baseUrl}/supplier/products?page=1&per_page=100'),
        headers: _headers,
      );

      // ✅ Traiter les statistiques
      if (statsResponse.statusCode == 200) {
        final statsData = json.decode(statsResponse.body);
        if (statsData['success'] && statsData['data'] != null) {
          final stats = statsData['data'];

          _totalOrders = _toInt(stats['total_orders']);
          _pendingOrders = _toInt(stats['pending_orders']);
          _confirmedOrders = _toInt(stats['confirmed_orders']);
          _preparingOrders = _toInt(stats['preparing_orders']);
          _deliveringOrders = _toInt(stats['delivering_orders']);
          _deliveredOrders = _toInt(stats['delivered_orders']);
          _cancelledOrders = _toInt(stats['cancelled_orders']);
          _totalSales = _toDouble(stats['total_revenue']);

          print('📊 Stats dashboard chargées: $_totalOrders commandes, $_totalSales MAD');
        }
      }

      // ✅ Traiter les commandes récentes
      if (ordersResponse.statusCode == 200) {
        final ordersData = json.decode(ordersResponse.body);
        final List orders = ordersData['data']['data'] ?? ordersData['data'] ?? [];

        _recentTransactions = orders.map((order) {
          double montant = _toDouble(order['amount_total'] ?? order['total']);

          // Récupérer le nom du client
          String clientName = 'Client';
          if (order['customer'] != null) {
            clientName = order['customer']['name'] ??
                order['customer']['company_name'] ??
                'Client';
          } else if (order['partner'] != null) {
            clientName = order['partner']['name'] ?? 'Client';
          }

          return {
            'clientName': clientName,
            'commandeRef': order['order_number'] ?? order['name'] ?? 'Commande',
            'montant': montant,
            'statut': order['status'] ?? 'pending',
            'timeInfo': _formatTimeAgo(order['created_at']),
            'isDelayed': order['status'] == 'pending',
          };
        }).toList();

        print('📦 Commandes récentes: ${_recentTransactions.length}');
      }

      // ✅ Traiter les produits
      if (productsResponse.statusCode == 200) {
        final productsData = json.decode(productsResponse.body);
        final List products = productsData['data']['data'] ?? productsData['data'] ?? [];

        // Calculer les produits en rupture
        _outOfStockProducts = products.where((p) {
          int stock = _toInt(p['stock_quantity']);
          int minStock = _toInt(p['min_stock_alert']);
          if (minStock == 0) minStock = 5;
          return stock <= minStock;
        }).length;

        // Produits populaires (triés par popular_rank)
        final sortedProducts = List.from(products);
        sortedProducts.sort((a, b) {
          int rankA = _toInt(a['popular_rank']);
          int rankB = _toInt(b['popular_rank']);
          return rankB.compareTo(rankA);
        });
        _popularProducts = sortedProducts.take(5).map((p) => Product.fromJson(p)).toList();

        print('📦 Produits chargés: ${products.length}');
      }

      // Données du graphique (simulées pour l'instant)
      _salesChartData = [
        {'month': 'Janv.', 'value': 45000.0, 'isActive': false},
        {'month': 'Fév.', 'value': 38000.0, 'isActive': false},
        {'month': 'Mars', 'value': 52000.0, 'isActive': true},
        {'month': 'Avril', 'value': 48000.0, 'isActive': false},
        {'month': 'Mai', 'value': 63000.0, 'isActive': false},
        {'month': 'Juin', 'value': 58000.0, 'isActive': false},
      ];

      notifyListeners();

    } catch (e) {
      print('❌ Erreur dashboard: $e');
      _setError('Erreur réseau: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null) return 'Récent';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
      } else if (difference.inMinutes > 0) {
        return 'Il y a ${difference.inMinutes} min';
      } else {
        return 'À l\'instant';
      }
    } catch (e) {
      return 'Récent';
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
}