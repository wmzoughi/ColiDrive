// lib/services/merchant_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/order.dart';
import '../models/supplier.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';
import 'auth_service.dart';

class MerchantService extends ChangeNotifier {
  // Données du dashboard
  double _creditBalance = 0.0;
  double _creditLimit = 0.0;
  List<Product> _popularProducts = [];
  List<Order> _recentOrders = [];
  List<Supplier> _suppliers = [];
  List<Product> _promoProducts = [];

  // Statistiques
  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _deliveredOrders = 0;

  bool _isLoading = false;
  String? _error;

  // Getters
  double get creditBalance => _creditBalance;
  double get creditLimit => _creditLimit;
  double get availableCredit => _creditLimit - _creditBalance;
  double get creditUsagePercentage => _creditLimit > 0 ? (_creditBalance / _creditLimit) * 100 : 0;
  List<Product> get popularProducts => _popularProducts;
  List<Order> get recentOrders => _recentOrders;
  List<Supplier> get suppliers => _suppliers;
  List<Product> get promoProducts => _promoProducts;
  int get totalOrders => _totalOrders;
  int get pendingOrders => _pendingOrders;
  int get deliveredOrders => _deliveredOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get token => _authService.token;

  final AuthService _authService;

  MerchantService(this._authService);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer ${_authService.token}',
  };

  // Formater en Dinar Tunisien (DT)
  String formatMAD(double amount, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    // Format: 1.234,56 MAD ou ١٬٢٣٤٫٥٦ درهم
    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} ${localizations.currency}';
  }
  // ========== CHARGEMENT DES DONNÉES ==========

  Future<void> loadDashboardData() async {
    _setLoading(true);
    _clearError();

    try {
      // Charger toutes les données en parallèle
      await Future.wait([
        _loadCreditInfo(),
        _loadPopularProducts(),
        _loadRecentOrders(),
        _loadSuppliers(),
        _loadPromoProducts(),
        _loadOrderStats(),
      ]);

      notifyListeners();
    } catch (e) {
      _setError('Erreur de chargement: ${e.toString()}');
      debugPrint('Dashboard data error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ========== CHARGEMENT SPÉCIFIQUE ==========

  Future<void> _loadCreditInfo() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/merchant/credit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _creditBalance = (data['data']['balance'] ?? 0).toDouble();
          _creditLimit = (data['data']['limit'] ?? 0).toDouble();
        }
      }
    } catch (e) {
      debugPrint('Error loading credit: $e');
    }
  }

  Future<void> _loadPopularProducts() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/products?order_by=popular_rank&order_dir=desc&per_page=10'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List productsJson = data['data']['data'] ?? data['data'] ?? [];
        _popularProducts = productsJson.map((p) => Product.fromJson(p)).toList();
      }
    } catch (e) {
      debugPrint('Error loading popular products: $e');
    }
  }

  Future<void> _loadPromoProducts() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/products?in_promotion=true&per_page=10'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List productsJson = data['data']['data'] ?? data['data'] ?? [];
        _promoProducts = productsJson.map((p) => Product.fromJson(p)).toList();
      }
    } catch (e) {
      debugPrint('Error loading promo products: $e');
    }
  }

  Future<void> _loadRecentOrders() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/merchant/orders?per_page=5&order_by=create_date&order_dir=desc'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List ordersJson = data['data']['data'] ?? data['data'] ?? [];
        _recentOrders = ordersJson.map((o) => Order.fromJson(o)).toList();
      }
    } catch (e) {
      debugPrint('Error loading recent orders: $e');
    }
  }

  Future<void> _loadSuppliers() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/suppliers/available'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _suppliers = (data['data'] as List)
            .map((s) => Supplier.fromJson(s))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading suppliers: $e');
    }
  }

  Future<void> _loadOrderStats() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/merchant/orders/stats'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _totalOrders = data['data']['total'] ?? 0;
          _pendingOrders = data['data']['pending'] ?? 0;
          _deliveredOrders = data['data']['delivered'] ?? 0;
        }
      }
    } catch (e) {
      debugPrint('Error loading order stats: $e');
    }
  }

  // ========== RECHERCHE DE PRODUITS ==========

  Future<List<Product>> searchProducts(String query, {int? categoryId, bool? inPromotion}) async {
    try {
      String url = '${AppConstants.baseUrl}/products?search=$query';
      if (categoryId != null) {
        url += '&categ_id=$categoryId';
      }
      if (inPromotion != null && inPromotion) {
        url += '&in_promotion=true';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List productsJson = data['data']['data'] ?? data['data'] ?? [];
        return productsJson.map((p) => Product.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error searching products: $e');
      return [];
    }
  }

  // ========== GESTION DES FOURNISSEURS ==========

  Future<Map<String, dynamic>> addSupplier(int supplierId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/suppliers/add'),
        headers: _headers,
        body: json.encode({'supplier_id': supplierId}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await _loadSuppliers(); // Recharger la liste
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'ajout',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau: ${e.toString()}',
      };
    }
  }

  Future<bool> removeSupplier(int supplierId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/suppliers/$supplierId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        await _loadSuppliers();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing supplier: $e');
      return false;
    }
  }

  // ========== GESTION DES COMMANDES ==========

  Future<List<Order>> getOrders({
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
  }) async {
    try {
      String url = '${AppConstants.baseUrl}/merchant/orders?page=$page';
      if (status != null) {
        url += '&status=$status';
      }
      if (fromDate != null) {
        url += '&from_date=${fromDate.toIso8601String().split('T').first}';
      }
      if (toDate != null) {
        url += '&to_date=${toDate.toIso8601String().split('T').first}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List ordersJson = data['data']['data'] ?? data['data'] ?? [];
        return ordersJson.map((o) => Order.fromJson(o)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting orders: $e');
      return [];
    }
  }

  Future<Order?> getOrderDetails(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/merchant/orders/$orderId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return Order.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting order details: $e');
      return null;
    }
  }

  // ========== UTILITAIRES ==========

  void refresh() {
    loadDashboardData();
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}