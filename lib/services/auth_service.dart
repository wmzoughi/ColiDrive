// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import 'cart_service.dart';
import 'order_service.dart';
import 'dashboard_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;

  // Références aux services (seront injectés depuis main.dart)
  CartService? _cartService;
  OrderService? _orderService;
  DashboardService? _dashboardService;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _currentUser != null;

  // Méthodes pour injecter les services (appelées depuis main.dart)
  void setCartService(CartService cartService) {
    _cartService = cartService;
  }

  void setOrderService(OrderService orderService) {
    _orderService = orderService;
  }

  void setDashboardService(DashboardService dashboardService) {
    _dashboardService = dashboardService;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      if (_token != null) {
        final userJson = prefs.getString('user_data');
        if (userJson != null) {
          _currentUser = User.fromJson(json.decode(userJson));
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Init error: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      String? sessionId;
      final prefs = await SharedPreferences.getInstance();
      sessionId = prefs.getString('cart_session_id');

      print('🔐 Tentative de login avec session_id: $sessionId');

      final Map<String, String> headers = {'Content-Type': 'application/json'};
      if (sessionId != null) {
        headers['X-Session-ID'] = sessionId;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: headers,
        body: json.encode({'email': email, 'password': password}),
      );

      print('📥 Réponse login: ${response.body}');
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await _saveAuthData(data['data']);

        if (data['data']['cart']?['session_id'] != null) {
          await prefs.setString('cart_session_id', data['data']['cart']['session_id']);
          print('✅ Nouveau session_id sauvegardé: ${data['data']['cart']['session_id']}');
        }

        // ✅ Utiliser les services directement (pas besoin de contexte)
        if (_cartService != null) {
          print('🔄 Rechargement du panier après login...');
          await _cartService!.loadCart();
        }

        if (_orderService != null) {
          print('🔄 Rechargement des commandes après login...');
          await _orderService!.getMyOrders();
        }

        if (_dashboardService != null) {
          print('🔄 Rechargement du dashboard après login...');
          await _dashboardService!.loadDashboardData();
        }

        _setLoading(false);
        return true;
      } else {
        _setError(data['message'] ?? 'Erreur de connexion');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('💥 Exception login: $e');
      _setError('Erreur réseau: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _clearError();

    try {
      String? sessionId;
      final prefs = await SharedPreferences.getInstance();
      sessionId = prefs.getString('cart_session_id');

      final Map<String, String> headers = {'Content-Type': 'application/json'};
      if (sessionId != null) {
        headers['X-Session-ID'] = sessionId;
      }

      String endpoint;
      if (userData['user_type'] == 'fournisseur') {
        endpoint = '${AppConstants.baseUrl}/auth/register/fournisseur';
      } else {
        endpoint = '${AppConstants.baseUrl}/auth/register/commercant';
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: json.encode(userData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success']) {
        await _saveAuthData(data['data']);

        if (_cartService != null) {
          if (data['data']['cart']?['session_id'] != null) {
            await prefs.setString('cart_session_id', data['data']['cart']['session_id']);
          }
          await _cartService!.loadCart();
        }

        _setLoading(false);
        return {'success': true};
      } else {
        _setLoading(false);
        return {
          'success': false,
          'errors': data['errors'] ?? {'general': [data['message'] ?? 'Erreur']}
        };
      }
    } catch (e) {
      _setLoading(false);
      return {
        'success': false,
        'errors': {'general': ['Erreur réseau: ${e.toString()}']}
      };
    }
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await http.post(
          Uri.parse('${AppConstants.baseUrl}/auth/logout'),
          headers: _headers,
        );
      } catch (e) {
        debugPrint('Logout error: $e');
      }
    }
    await _clearAuthData();

    if (_cartService != null) {
      _cartService!.clearLocalCart();
    }

    notifyListeners();
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    _token = data['access_token'];
    _currentUser = User.fromJson(data['user']);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setString('user_data', json.encode(data['user']));
    notifyListeners();
  }

  Future<void> _clearAuthData() async {
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}