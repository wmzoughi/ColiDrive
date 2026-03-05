// lib/services/dashboard_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/order.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import '../l10n/app_localizations.dart';

class DashboardService extends ChangeNotifier {
  // Statistiques
  int _totalOrders = 0;
  int _pendingOrders = 0;
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

  // Formater en dirhams marocain

  String formatMAD(double amount, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    // Format: 1.234,56 MAD ou ١٬٢٣٤٫٥٦ درهم
    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} ${localizations.currency}';
  }

  Future<void> loadDashboardData() async {
    _setLoading(true);
    _clearError();

    try {
      // Récupérer les commandes du fournisseur
      final ordersResponse = await http.get(
        Uri.parse('${AppConstants.baseUrl}/supplier/orders?page=1&per_page=100'),
        headers: _headers,
      );

      // Récupérer les produits du fournisseur
      final productsResponse = await http.get(
        Uri.parse('${AppConstants.baseUrl}/supplier/products?page=1&per_page=100'),
        headers: _headers,
      );

      if (ordersResponse.statusCode == 200 && productsResponse.statusCode == 200) {
        final ordersData = json.decode(ordersResponse.body);
        final productsData = json.decode(productsResponse.body);

        final List orders = ordersData['data']['data'] ?? ordersData['data'] ?? [];
        final List products = productsData['data']['data'] ?? productsData['data'] ?? [];

        // Calculer les statistiques
        _totalOrders = orders.length;
        _pendingOrders = orders.where((o) => o['status'] == 'pending' || o['delivery_status'] == 'pending').length;

        _totalSales = orders.fold(0.0, (sum, order) {
          return sum + (order['amount_total']?.toDouble() ?? 0.0);
        });

        // Produits en rupture (stock < seuil min)
        _outOfStockProducts = products.where((p) {
          int stock = p['stock_quantity'] ?? 0;
          int minStock = p['min_stock_alert'] ?? 5;
          return stock <= minStock;
        }).length;

        // Transactions récentes (les 5 dernières commandes)
        final recentOrders = orders.take(5).toList();
        _recentTransactions = recentOrders.map((order) {
          return {
            'clientName': order['partner']?['name'] ?? 'Client',
            'commandeRef': order['name'] ?? 'Commande ${order['id']}',
            'montant': (order['amount_total']?.toDouble() ?? 0.0),
            'statut': order['delivery_status'] == 'delivered' ? 'Livrée' : 'En retard',
            'timeInfo': _formatTimeAgo(order['create_date']),
            'isDelayed': order['delivery_status'] != 'delivered',
          };
        }).toList();

        // Produits populaires (triés par popular_rank)
        final sortedProducts = List.from(products);
        sortedProducts.sort((a, b) {
          int rankA = a['popular_rank'] ?? 0;
          int rankB = b['popular_rank'] ?? 0;
          return rankB.compareTo(rankA);
        });
        _popularProducts = sortedProducts.take(5).map((p) => Product.fromJson(p)).toList();

        // Données du graphique (simulées pour l'instant)
        _salesChartData = [
          {'month': 'Janv.', 'value': 45000, 'isActive': false},
          {'month': 'Fév.', 'value': 38000, 'isActive': false},
          {'month': 'Mars.', 'value': 52000, 'isActive': true},
          {'month': 'Avril', 'value': 48000, 'isActive': false},
          {'month': 'Mai', 'value': 63000, 'isActive': false},
          {'month': 'Juin', 'value': 58000, 'isActive': false},
        ];

        notifyListeners();
      } else {
        _setError('Erreur de chargement des données');
      }
    } catch (e) {
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
    _isLoading = loading;
    notifyListeners();
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